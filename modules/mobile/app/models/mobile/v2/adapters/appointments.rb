# frozen_string_literal: true

module Mobile
  module V2
    module Adapters
      # VA Appointments come in various shapes and sizes. This class adapts
      # VA on-site, video connect, video connect atlas, and video connect with
      # a GFE to a common schema.
      #
      # @example create a new instance and parse incoming data
      #   Mobile::V0::Adapters::VAAppointments.new.parse(appointments)
      #
      class Appointments
        APPOINTMENT_TYPES = {
          va: 'VA',
          cc: 'COMMUNITY_CARE',
          va_video_connect_home: 'VA_VIDEO_CONNECT_HOME',
          va_video_connect_atlas: 'VA_VIDEO_CONNECT_ATLAS'
        }.freeze

        CANCELLED_STATUS = [
          'CANCELLED BY CLINIC & AUTO RE-BOOK',
          'CANCELLED BY CLINIC',
          'CANCELLED BY PATIENT & AUTO-REBOOK',
          'CANCELLED BY PATIENT'
        ].freeze

        FUTURE_HIDDEN = %w[NO-SHOW DELETED].freeze

        FUTURE_HIDDEN_STATUS = [
          'ACT REQ/CHECKED IN',
          'ACT REQ/CHECKED OUT'
        ].freeze

        PAST_HIDDEN = %w[FUTURE DELETED null <null> Deleted].freeze

        PAST_HIDDEN_STATUS = %w[
          arrived
          noshow
          fulfilled
        ].freeze

        STATUSES = {
          booked: 'BOOKED',
          cancelled: 'CANCELLED',
          hidden: 'HIDDEN',
          proposed: 'PROPOSED',
          pending: 'PENDING'
        }.freeze

        VIDEO_GFE_CODE = 'MOBILE_GFE'
        COVID_VACCINE_CODE = 'CDQC'

        # Takes a result set of VA appointments from the appointments web service
        # and returns the set adapted to a common schema.
        #
        # @appointments Hash a list of various VA appointment types
        #
        # @return Hash the adapted list
        #
        def parse(appointments)
          appointments_list = appointments.dig(:data) || []

          appointments_list.map do |appointment_hash|
            build_appointment_model(appointment_hash)
          end
        end

        private

        # rubocop:disable Metrics/MethodLength
        def build_appointment_model(appointment_hash)
          binding.pry
          facility_id = Mobile::V0::Appointment.toggle_non_prod_id!(
            appointment_hash[:locationId]
          )
          sta6aid = Mobile::V0::Appointment.toggle_non_prod_id!(
            appointment_hash[:locationId]
          )
          type = parse_by_appointment_type(appointment_hash, appointment_hash[:kind])
          start_date_utc = start_date_utc(appointment_hash)
          time_zone = time_zone(facility_id)
          start_date_local = start_date_utc.in_time_zone(time_zone)
          status = status(appointment_hash)

          adapted_hash = {
            id: appointment_hash[:id],
            appointment_type: type,
            cancel_id: appointment_hash[:id],
            comment: appointment_hash[:comment] || appointment_hash.dig(:reasonCode, :text),
            facility_id: facility_id,
            sta6aid: sta6aid,
            healthcare_provider: nil, # healthcare_provider is currently only used by CC appointments
            healthcare_service: healthcare_service(appointment_hash, type),
            location: location(appointment_hash[:telehealth], facility_id),
            minutes_duration: minutes_duration(appointment_hash[:minutesDuration], type),
            phone_only: appointment_hash[:kind] == 'phone',
            start_date_local: start_date_local,
            start_date_utc: start_date_utc,
            status: status,
            status_detail: nil,
            time_zone: time_zone,
            vetext_id: vetext_id(appointment_hash, start_date_local),
            reason: appointment_hash.dig(:reasonCode, :coding, 0, :code),
            is_covid_vaccine: covid_vaccine?(appointment_hash),
            is_pending: false,
            proposed_times: nil,
            type_of_care: nil,
            patient_phone_number: nil,
            patient_email: nil,
            best_time_to_call: nil,
            friendly_location_name: nil
          }

          Rails.logger.info('metric.mobile.appointment.type', type: type)

          Mobile::V0::Appointment.new(adapted_hash)
        end
        # rubocop:enable Metrics/MethodLength

        def vetext_id(appointment_hash, start_date_local)
          "#{appointment_hash[:clinic]};#{start_date_local.strftime('%Y%m%d.%H%S%M')}"
        end

        def status(appointment_hash)
          status = appointment_hash[:status]
          return STATUSES[:hidden] if PAST_HIDDEN_STATUS.include?(status)

          status
        end

        def start_date_utc(appointment_hash)
          DateTime.parse(appointment_hash[:start] || appointment_hash.dig(:requestedPeriods, 0, :start))
        end

        def parse_by_appointment_type(appointment_hash, type)
          case type
          when 'phone'
            APPOINTMENT_TYPES[:va]
          when 'clinic'
            APPOINTMENT_TYPES[:va]
          when 'telehealth'
            if appointment_hash[:telehealth][:atlas].nil?
              APPOINTMENT_TYPES[:va_video_connect_home]
            else
              APPOINTMENT_TYPES[:va_video_connect_atlas]
            end
          end
        end

        # rubocop:disable Metrics/MethodLength
        def location(telehealth, facility_id)
          facility = Mobile::VA_FACILITIES_BY_ID["dfn-#{facility_id}"]
          location = {
            id: facility_id,
            name: facility ? facility[:name] : nil,
            address: {
              street: nil,
              city: nil,
              state: nil,
              zip_code: nil
            },
            lat: nil,
            long: nil,
            phone: {
              area_code: nil,
              number: nil,
              extension: nil
            },
            url: nil,
            code: nil
          }

          location_by_type(telehealth, location)
        end
        # rubocop:enable Metrics/MethodLength

        def location_by_type(telehealth, location)
          if telehealth
            location_atlas(telehealth, location)
          else
            location
          end
        end

        def time_zone(facility_id)
          facility = Mobile::VA_FACILITIES_BY_ID["dfn-#{facility_id}"]
          facility ? facility[:time_zone] : nil
        end

        def healthcare_service(appointment_hash, type)
          va?(type) ? appointment_hash[:service_name] : appointment_hash.dig(:practitioners, 0, :practitioner_name)
        end

        def va_clinic_name(appointment_hash, details)
          appointment_hash[:clinic_friendly_name].presence || details.dig(
            :clinic, :name
          )
        end

        def location_atlas(telehealth, location)
          address = telehealth.dig(:atlas, :address)
          location[:address] = {
            street: address[:streetAddress],
            city: address[:city],
            state: address[:state],
            zip_code: address[:zipCode],
            country: address[:country]
          }
          location[:url] = telehealth[:url]
          location[:code] = telehealth[:atlas][:confirmationCode]
          location
        end

        def minutes_duration(minutesDuration, type)
          # not in raw data, matches va.gov default for cc appointments
          return 60 if type == APPOINTMENT_TYPES[:cc] && minutesDuration.nil?

          minutesDuration
        end

        def booked_va_appointment?(status, type)
          type == APPOINTMENT_TYPES[:va] && status == STATUSES[:booked]
        end

        def covid_vaccine?(appointment)
          appointment[:serviceType] == 'covid'
        end

        def va?(type)
          type == APPOINTMENT_TYPES[:va]
        end
      end
    end
  end
end
