# frozen_string_literal: true

require 'lighthouse/facilities/client'

module Mobile
  module V0
    module Appointments
      class Proxy
        CANCEL_CODE = 'PC'
        CANCEL_ASSIGNING_AUTHORITY = 'ICN'
        UNABLE_TO_KEEP_APPOINTMENT = '5'
        VALID_CANCEL_CODES = %w[4 5 6].freeze

        def initialize(user)
          @user = user
        end

        def fetch_facilities_from_appointments(appointments)
          facility_ids = appointments.map(&:id_for_address).uniq

          return nil unless facility_ids.any?

          fetch_facilities_from_ids(facility_ids, nil)
        end

        def fetch_facilities_from_ids(facility_ids, include_children)
          if Flipper.enabled?(:mobile_appointment_use_VAOS_MFS)
            new_fetch_facilities(facility_ids, include_children)
          else
            legacy_fetch_facilities(facility_ids)
          end
        end

        def get_appointments(start_date:, end_date:, pagination_params:)
          if Flipper.enabled?(:mobile_appointment_use_VAOS_v2)
            response = vaos_v2_appointments_service.get_appointments(start_date, end_date,nil, pagination_params)
            normalize_v2_appointments(response)
          elsif Flipper.enabled?(:mobile_appointment_requests)
            responses = fetch_appointments(start_date, end_date)
            normalize_appointments(responses, start_date, end_date)
          else
            legacy_fetch_appointments(start_date, end_date)
          end
        end

        def put_cancel_appointment(params)
          facility_id = Mobile::V0::Appointment.toggle_non_prod_id!(params[:facilityId])

          cancel_reasons = get_facility_cancel_reasons(facility_id)
          cancel_reason = extract_valid_reason(cancel_reasons.map(&:number))

          raise Common::Exceptions::BackendServiceException, 'MOBL_404_cancel_reason_not_found' if cancel_reason.nil?

          put_params = {
            appointment_time: params[:appointmentTime].strftime('%m/%d/%Y %H:%M:%S'),
            clinic_id: params[:clinicId],
            cancel_reason: cancel_reason,
            cancel_code: CANCEL_CODE,
            clinic_name: params['healthcareService'],
            facility_id: facility_id,
            remarks: ''
          }

          vaos_appointments_service.put_cancel_appointment(put_params)
        rescue Common::Exceptions::BackendServiceException => e
          handle_cancel_error(e, params)
        end

        def get_appointment_request(id)
          vaos_appointment_requests_service.get_request(id)[:data]
        end

        def put_cancel_appointment_request(id, request)
          parsed_request = request.as_json['table']
          parsed_request['status'] = 'Cancelled'
          parsed_request['appointment_request_detail_code'] = ['DETCODE8']

          vaos_appointment_requests_service.put_request(id, parsed_request)
        rescue Common::Exceptions::BackendServiceException => e
          handle_cancel_error(e, parsed_request)
        end

        private

        def normalize_v2_appointments(response)
          appointments = merge_clinics(response[:data])
          appointments = merge_facilities(appointments)
          appointments = merge_providers(appointments)

          appointments = v2_appointment_adapter.parse(appointments)

          # There's currently a bug in the underlying Community Care service
          # where date ranges are not being respected
          # cc_appointments.select! do |appointment|
          #  appointment.start_date_utc.between?(start_date, end_date)
          # end

          appointments.sort_by(&:start_date_utc)
        end

        def mobile_ppms_service
          VAOS::V2::MobilePPMSService.new(@user)
        end

        def normalize_appointments(responses, start_date, end_date)
          va_appointments = va_appointments_adapter.parse(responses[:va][:response].body)
          cc_appointments = cc_appointments_adapter.parse(responses[:cc][:response].body)
          va_appointment_requests, cc_appointment_requests = requests_adapter.parse(responses[:requests])

          # There's currently a bug in the underlying Community Care service
          # where date ranges are not being respected
          cc_appointments.select! do |appointment|
            appointment.start_date_utc.between?(start_date, end_date)
          end

          facilities = fetch_facilities_from_appointments(va_appointments + va_appointment_requests)
          va_appointments = backfill_appointments_with_facilities(va_appointments, facilities)
          va_appointment_requests = backfill_appointments_with_facilities(va_appointment_requests, facilities)

          (va_appointments + cc_appointments + va_appointment_requests + cc_appointment_requests)
            .sort_by(&:start_date_utc)
        end

        def legacy_fetch_appointments(start_date, end_date)
          va_response, cc_response = Parallel.map(
            [fetch_va_appointments(start_date, end_date), fetch_cc_appointments(start_date, end_date)],
            in_threads: 2, &:call
          )

          errors = [va_response[:error], cc_response[:error]].compact

          if errors.size.positive?
            Rails.logger.error('Mobile Legacy Appointments Error: ', errors: errors)
            raise Common::Exceptions::BackendServiceException, 'MOBL_502_upstream_error'
          end

          va_appointments = va_appointments_adapter.parse(va_response[:response].body)
          cc_appointments = cc_appointments_adapter.parse(cc_response[:response].body)

          if va_appointments.any?
            facilities = fetch_facilities_from_appointments(va_appointments)
            va_appointments = backfill_appointments_with_facilities(va_appointments, facilities)
          end

          # There's currently a bug in the underlying Community Care service
          # where date ranges are not being respected
          cc_appointments.select! do |appointment|
            appointment.start_date_utc.between?(start_date, end_date)
          end

          (va_appointments + cc_appointments).sort_by(&:start_date_utc)
        end

        def merge_clinics(appointments)
          cached_clinics = {}
          appointments.each do |appt|
            unless appt[:clinic].nil?
              unless cached_clinics[appt[:clinic]]
                clinic = get_clinic(appt[:location_id], appt[:clinic])
                cached_clinics[appt[:clinic]] = clinic
              end
              if cached_clinics[appt[:clinic]]&.[](:service_name)
                appt[:service_name] = cached_clinics[appt[:clinic]][:service_name]
              end
              if cached_clinics[appt[:clinic]]&.[](:physical_location)
                appt[:physical_location] = cached_clinics[appt[:clinic]][:physical_location]
              end
            end
          end
        end

        def merge_providers(appointments)
          appointments.each do |appt|
            appt[:practitioners]&.each do |practitioner|
              provider = get_provider(practitioner.dig(:identifier, 0, :value))
              practitioner[:practitioner_name] = provider[:name]
            end
          end
        end

        def get_provider(provider_id)
          mobile_ppms_service.get_provider(provider_id)
        rescue Common::Exceptions::BackendServiceException
          Rails.logger.error("Mobile: Error fetching provider #{provider_id} ")
        end

        def merge_facilities(appointments)
          cached_facilities = {}
          appointments.each do |appt|
            unless appt[:location_id].nil?
              unless cached_facilities[appt[:location_id]]
                facility = get_facility(appt[:location_id])
                cached_facilities[appt[:location_id]] = facility
              end

              appt[:location] = cached_facilities[appt[:location_id]] if cached_facilities[appt[:location_id]]
            end
          end
        end

        def get_clinic(location_id, clinic_id)
          clinics = v2_systems_service.get_facility_clinics(location_id: location_id, clinic_ids: clinic_id)
          clinics.first unless clinics.empty?
        rescue Common::Exceptions::BackendServiceException
          Rails.logger.error(
            "Error fetching clinic #{clinic_id} for location #{location_id}",
            clinic_id: clinic_id,
            location_id: location_id
          )
        end

        def get_facility(location_id)
          vaos_mobile_facility_service.get_facility(location_id)
        rescue Common::Exceptions::BackendServiceException
          Rails.logger.error(
            "Error fetching facility details for location_id #{location_id}",
            location_id: location_id
          )
        end

        def _include
          params[:_include]&.split(',')
        end

        def fetch_appointments(start_date, end_date)
          va_response, cc_response, requests_response = Parallel.map(
            [
              fetch_va_appointments(start_date, end_date),
              fetch_cc_appointments(start_date, end_date),
              fetch_appointment_requests
            ], in_threads: 3, &:call
          )

          # appointment requests are fetched by a service that raises on error
          errors = [va_response[:error], cc_response[:error]].compact
          if errors.size.positive?
            Rails.logger.error('Mobile Appointments w/ Requests Error: ', errors: errors)
            raise Common::Exceptions::BackendServiceException, 'MOBL_502_upstream_error'
          end

          { va: va_response, cc: cc_response, requests: requests_response }
        end

        def new_fetch_facilities(facility_ids, include_children)
          ids = facility_ids.join(',')

          facility_ids.each do |facility_id|
            Rails.logger.info('metric.mobile.appointment.facility', facility_id: facility_id)
          end
          vaos_facilities = vaos_mobile_facility_service.get_facilities(ids: ids, children: include_children, type: nil)
          vaos_facilities[:data]
        end

        def legacy_fetch_facilities(ids)
          ids.each do |facility_id|
            Rails.logger.info('metric.mobile.appointment.facility', facility_id: facility_id)
          end
          Mobile::FacilitiesHelper.get_facilities(ids)
        end

        def backfill_appointments_with_facilities(appointments, facilities)
          va_facilities_adapter.map_appointments_to_facilities(appointments, facilities)
        end

        def extract_valid_reason(cancel_reason_codes)
          valid_codes = cancel_reason_codes & VALID_CANCEL_CODES
          return nil if valid_codes.empty?
          return UNABLE_TO_KEEP_APPOINTMENT if unable_to_keep_appointment?(valid_codes)

          valid_codes.first
        end

        def get_facility_cancel_reasons(facility_id)
          vaos_systems_service.get_cancel_reasons(facility_id)
        end

        def unable_to_keep_appointment?(valid_codes)
          valid_codes.include? UNABLE_TO_KEEP_APPOINTMENT
        end

        def handle_cancel_error(e, params)
          if e.original_status == 409
            Rails.logger.info(
              'mobile cancel appointment facility not supported',
              clinic_id: params[:clinicId],
              facility_id: params[:facilityId] || params.dig(:facility, :facility_code)
            )
            raise Common::Exceptions::BackendServiceException, 'MOBL_409_facility_not_supported'
          end
          raise e
        end

        def appointments_service
          Mobile::V0::Appointments::Service.new(@user)
        end

        def fetch_va_appointments(start_date, end_date)
          lambda {
            appointments_service.fetch_va_appointments(start_date, end_date)
          }
        end

        def fetch_cc_appointments(start_date, end_date)
          lambda {
            appointments_service.fetch_cc_appointments(start_date, end_date)
          }
        end

        # fetches all appointment requests created in the past 90 days
        # this mimics the behavior of the web app
        def fetch_appointment_requests
          lambda {
            end_date = Time.zone.today
            start_date = end_date - 90.days
            service = VAOS::AppointmentRequestsService.new(@user)
            response = service.get_requests(start_date, end_date)
            response[:data]
          }
        end

        def vaos_v2_appointments_service
          VAOS::V2::AppointmentsService.new(@user)
        end

        def v2_appointment_adapter
          Mobile::V2::Adapters::Appointments.new
        end

        def v2_systems_service
          VAOS::V2::SystemsService.new(@user)
        end

        def vaos_appointments_service
          VAOS::AppointmentService.new(@user)
        end

        def vaos_appointment_requests_service
          VAOS::AppointmentRequestsService.new(@user)
        end

        def vaos_mobile_facility_service
          VAOS::V2::MobileFacilityService.new(@user)
        end

        def vaos_systems_service
          VAOS::SystemsService.new(@user)
        end

        def va_appointments_adapter
          Mobile::V0::Adapters::VAAppointments.new
        end

        def va_facilities_adapter
          Mobile::V0::Adapters::VAFacilities.new
        end

        def cc_appointments_adapter
          Mobile::V0::Adapters::CommunityCareAppointments.new
        end

        def requests_adapter
          Mobile::V0::Adapters::AppointmentRequests.new
        end
      end
    end
  end
end
