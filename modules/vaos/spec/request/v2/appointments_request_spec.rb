# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'vaos appointments', type: :request, skip_mvi: true do
  include SchemaMatchers
  mock_clinic = {
    'service_name': 'service_name',
    'physical_location': 'physical_location',
    'friendly_name': 'friendly_name'
  }

  mock_clinic_without_physical_location = {
    'service_name': 'service_name'
  }

  mock_facility = {
    'test' => 'test',
    'timezone' => {
      'timeZoneId' => 'America/New_York'
    }
  }

  before do
    Flipper.enable('va_online_scheduling')
    sign_in_as(current_user)
    allow_any_instance_of(VAOS::UserService).to receive(:session).and_return('stubbed_token')
    allow_any_instance_of(VAOS::V2::AppointmentsController).to receive(:get_clinic).and_return(mock_clinic)
    allow_any_instance_of(VAOS::V2::AppointmentsController).to receive(:get_facility).and_return(mock_facility)
  end

  let(:inflection_header) { { 'X-Key-Inflection' => 'camel' } }

  context 'with jacqueline morgan' do
    let(:current_user) { build(:user, :jac) }

    describe 'CREATE cc appointment' do
      let(:community_cares_request_body) do
        FactoryBot.build(:appointment_form_v2, :community_cares).attributes
      end

      it 'creates the cc appointment' do
        VCR.use_cassette('vaos/v2/appointments/post_appointments_cc_200_2222022',
                         match_requests_on: %i[method path query]) do
          post '/vaos/v2/appointments', params: community_cares_request_body, headers: inflection_header
          expect(response).to have_http_status(:created)
          expect(json_body_for(response)).to match_camelized_schema('vaos/v2/appointment', { strict: false })
        end
      end

      it 'returns a 400 error' do
        VCR.use_cassette('vaos/v2/appointments/post_appointments_400', match_requests_on: %i[method path query]) do
          post '/vaos/v2/appointments', params: community_cares_request_body
          expect(response).to have_http_status(:bad_request)
          expect(JSON.parse(response.body)['errors'][0]['status']).to eq('400')
          expect(JSON.parse(response.body)['errors'][0]['detail']).to eq(
            'the patientIcn must match the ICN in the request URI'
          )
        end
      end
    end

    describe 'CREATE va appointment' do
      let(:va_booked_request_body) do
        FactoryBot.build(:appointment_form_v2, :va_booked).attributes
      end

      let(:va_proposed_request_body) do
        FactoryBot.build(:appointment_form_v2, :va_proposed_clinic).attributes
      end

      it 'creates the va appointment - proposed' do
        VCR.use_cassette('vaos/v2/appointments/post_appointments_va_proposed_clinic_200',
                         match_requests_on: %i[method path query]) do
          post '/vaos/v2/appointments', params: va_proposed_request_body, headers: inflection_header
          expect(response).to have_http_status(:created)
          expect(json_body_for(response)).to match_camelized_schema('vaos/v2/appointment', { strict: false })
        end
      end

      it 'creates the va appointment - booked' do
        VCR.use_cassette('vaos/v2/appointments/post_appointments_va_booked_200_JACQUELINE_M',
                         match_requests_on: %i[method path query]) do
          post '/vaos/v2/appointments', params: va_booked_request_body, headers: inflection_header
          expect(response).to have_http_status(:created)
          expect(json_body_for(response)).to match_camelized_schema('vaos/v2/appointment', { strict: false })
        end
      end
    end

    describe 'GET appointments' do
      let(:start_date) { Time.zone.parse('2022-01-01T19:25:00Z') }
      let(:end_date) { Time.zone.parse('2022-12-01T19:45:00Z') }
      let(:params) { { start: start_date, end: end_date } }

      context 'requests a list of appointments' do
        it 'has access and returns va appointments and honors includes' do
          VCR.use_cassette('vaos/v2/appointments/get_appointments_200', match_requests_on: %i[method path query],
                                                                        allow_playback_repeats: true) do
            get '/vaos/v2/appointments?_include=facilities,clinics', params: params, headers: inflection_header
            data = JSON.parse(response.body)['data']
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_a(String)
            expect(data.size).to eq(23)
            expect(data[0]['attributes']['serviceName']).to eq('service_name')
            expect(data[0]['attributes']['physicalLocation']).to eq('physical_location')
            expect(data[0]['attributes']['friendlyName']).to eq('friendly_name')
            expect(data[0]['attributes']['location']).to eq(mock_facility)
            expect(response).to match_camelized_response_schema('vaos/v2/appointments', { strict: false })
          end
        end

        it 'has access and returns va appointments and honors includes with no physical_location field' do
          allow_any_instance_of(VAOS::V2::AppointmentsController).to receive(:get_clinic)
            .and_return(mock_clinic_without_physical_location)
          VCR.use_cassette('vaos/v2/appointments/get_appointments_200', match_requests_on: %i[method path query],
                                                                        allow_playback_repeats: true) do
            get '/vaos/v2/appointments?_include=facilities,clinics', params: params, headers: inflection_header
            data = JSON.parse(response.body)['data']
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_a(String)
            expect(data.size).to eq(23)
            expect(data[0]['attributes']['serviceName']).to eq('service_name')
            expect(data[0]['attributes']['location']).to eq(mock_facility)
            expect(response).to match_camelized_response_schema('vaos/v2/appointments', { strict: false })
          end
        end

        it 'has access and returns va appointments' do
          VCR.use_cassette('vaos/v2/appointments/get_appointments_200', match_requests_on: %i[method path query],
                                                                        allow_playback_repeats: true) do
            get '/vaos/v2/appointments', params: params, headers: inflection_header
            data = JSON.parse(response.body)['data']
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_a(String)
            expect(data.size).to eq(23)
            expect(data[0]['attributes']['serviceName']).to eq(nil)
            expect(data[0]['attributes']['location']).to eq(nil)
            expect(response).to match_camelized_response_schema('vaos/v2/appointments', { strict: false })
          end
        end

        it 'has access and returns va appointments when systems service fails' do
          allow_any_instance_of(VAOS::V2::AppointmentsController).to receive(:get_clinic).and_call_original
          VCR.use_cassette('vaos/v2/appointments/get_appointments_200_with_system_service_500',
                           match_requests_on: %i[method path query], allow_playback_repeats: true) do
            get '/vaos/v2/appointments', params: params, headers: inflection_header
            data = JSON.parse(response.body)['data']
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_a(String)
            expect(data.size).to eq(18)
            expect(data[0]['attributes']['serviceName']).to eq(nil)
            expect(response).to match_camelized_response_schema('vaos/v2/appointments', { strict: false })
          end
        end

        it 'has access and returns va appointments when mobile facility service fails' do
          allow_any_instance_of(VAOS::V2::AppointmentsController).to receive(:get_facility).and_call_original
          VCR.use_cassette('vaos/v2/appointments/get_appointments_200_with_mobile_facility_service_500',
                           match_requests_on: %i[method path query], allow_playback_repeats: true) do
            get '/vaos/v2/appointments?_include=facilities', params: params, headers: inflection_header
            data = JSON.parse(response.body)['data']
            expect(response).to have_http_status(:ok)
            expect(response.body).to be_a(String)
            expect(data.size).to eq(18)
            expect(data[0]['attributes']['location']).to eq(nil)
            expect(data[17]['attributes']['location']).not_to eq(nil)
            expect(response).to match_camelized_response_schema('vaos/v2/appointments', { strict: false })
          end
        end

        it 'has access and returns va appointments given a date range and single status' do
          VCR.use_cassette('vaos/v2/appointments/get_appointments_single_status_200',
                           match_requests_on: %i[method path query]) do
            get '/vaos/v2/appointments?start=2022-01-01T19:25:00Z&end=2022-12-01T19:45:00Z&statuses=proposed',
                headers: inflection_header
            expect(response).to match_camelized_response_schema('vaos/v2/appointments', { strict: false })
            data = JSON.parse(response.body)['data']
            expect(data.size).to eq(4)
            expect(data[0]['attributes']['status']).to eq('proposed')
            expect(data[1]['attributes']['status']).to eq('proposed')
            expect(response).to match_camelized_response_schema('vaos/v2/va_appointments', { strict: false })
          end
        end

        it 'has access and returns va appointments given date a range and single status (as array)' do
          VCR.use_cassette('vaos/v2/appointments/get_appointments_single_status_200',
                           match_requests_on: %i[method path query]) do
            get '/vaos/v2/appointments?start=2022-01-01T19:25:00Z&end=2022-12-01T19:45:00Z&statuses[]=proposed',
                headers: inflection_header
            expect(response).to match_camelized_response_schema('vaos/v2/appointments', { strict: false })
            data = JSON.parse(response.body)['data']
            expect(data.size).to eq(4)
            expect(data[0]['attributes']['status']).to eq('proposed')
            expect(data[1]['attributes']['status']).to eq('proposed')
            expect(response).to match_camelized_response_schema('vaos/v2/va_appointments', { strict: false })
          end
        end

        it 'has access and returns va appointments given a date range and multiple statuses' do
          VCR.use_cassette('vaos/v2/appointments/get_appointments_multi_status_200',
                           match_requests_on: %i[method path query]) do
            get '/vaos/v2/appointments?start=2022-01-01T19:25:00Z&end=2022-12-01T19:45:00Z&statuses=proposed,booked',
                headers: inflection_header
            expect(response).to have_http_status(:ok)
            expect(response).to match_camelized_response_schema('vaos/v2/appointments', { strict: false })
            data = JSON.parse(response.body)['data']
            expect(data.size).to eq(4)
            expect(data[0]['attributes']['status']).to eq('proposed')
            expect(data[1]['attributes']['status']).to eq('booked')
            expect(response).to match_camelized_response_schema('vaos/v2/va_appointments', { strict: false })
          end
        end

        it 'has access and returns va appointments given a date range and multiple statuses (as Array)' do
          VCR.use_cassette('vaos/v2/appointments/get_appointments_multi_status_200',
                           match_requests_on: %i[method path query]) do
            get '/vaos/v2/appointments?start=2022-01-01T19:25:00Z&end=2022-12-01T19:45:00Z&statuses[]=proposed' \
                '&statuses[]=booked',
                headers: inflection_header
            expect(response).to have_http_status(:ok)
            expect(response).to match_camelized_response_schema('vaos/v2/appointments', { strict: false })
            data = JSON.parse(response.body)['data']
            expect(data.size).to eq(4)
            expect(data[0]['attributes']['status']).to eq('proposed')
            expect(data[1]['attributes']['status']).to eq('booked')
            expect(response).to match_camelized_response_schema('vaos/v2/va_appointments', { strict: false })
          end
        end

        it 'has access and returns va appointments having partial errors' do
          VCR.use_cassette('vaos/v2/appointments/get_appointments_v2_partial_error',
                           match_requests_on: %i[method path query]) do
            get '/vaos/v2/appointments?start=2022-01-01T19:25:00Z&end=2022-12-01T19:45:00Z&statuses[]=proposed',
                params: params, headers: inflection_header

            expect(response).to have_http_status(:multi_status)
            expect(response).to match_camelized_response_schema('vaos/v2/va_appointments', { strict: false })
          end
        end

        it 'returns a 400 error' do
          VCR.use_cassette('vaos/v2/appointments/get_appointments_400', match_requests_on: %i[method path query]) do
            get '/vaos/v2/appointments', params: { start: start_date }

            expect(response).to have_http_status(:bad_request)
            expect(JSON.parse(response.body)['errors'][0]['status']).to eq('400')
          end
        end
      end
    end

    describe 'GET appointment' do
      context 'when the VAOS service returns a single appointment ' do
        it 'has access and returns appointment - va proposed' do
          VCR.use_cassette('vaos/v2/appointments/get_appointment_200', match_requests_on: %i[method path query]) do
            get '/vaos/v2/appointments/70060', headers: inflection_header
            expect(response).to have_http_status(:ok)
            expect(json_body_for(response)).to match_camelized_schema('vaos/v2/appointment', { strict: false })
            data = JSON.parse(response.body)['data']

            expect(data['id']).to eq('70060')
            expect(data['attributes']['kind']).to eq('clinic')
            expect(data['attributes']['status']).to eq('proposed')
          end
        end

        it 'has access and returns appointment - cc proposed' do
          VCR.use_cassette('vaos/v2/appointments/get_appointment_200_JACQUELINE_M_PROPOSED',
                           match_requests_on: %i[method path query]) do
            get '/vaos/v2/appointments/72105', headers: inflection_header
            expect(response).to have_http_status(:ok)
            expect(json_body_for(response)).to match_camelized_schema('vaos/v2/appointment', { strict: false })
            data = JSON.parse(response.body)['data']

            expect(data['id']).to eq('72105')
            expect(data['attributes']['kind']).to eq('cc')
            expect(data['attributes']['status']).to eq('proposed')
          end
        end

        it 'has access and returns appointment - cc booked' do
          VCR.use_cassette('vaos/v2/appointments/get_appointment_200_JACQUELINE_M_BOOKED',
                           match_requests_on: %i[method path query]) do
            get '/vaos/v2/appointments/72106', headers: inflection_header
            expect(response).to have_http_status(:ok)
            expect(json_body_for(response)).to match_camelized_schema('vaos/v2/appointment', { strict: false })
            data = JSON.parse(response.body)['data']

            expect(data['id']).to eq('72106')
            expect(data['attributes']['kind']).to eq('cc')
            expect(data['attributes']['status']).to eq('booked')
          end
        end
      end

      context 'when the VAOS service errors on retrieving an appointment' do
        it 'returns a 502 status code' do
          VCR.use_cassette('vaos/v2/appointments/get_appointment_500', match_requests_on: %i[method path query]) do
            get '/vaos/v2/appointments/00000'
            expect(response).to have_http_status(:bad_gateway)
            expect(JSON.parse(response.body)['errors'][0]['code']).to eq('VAOS_502')
          end
        end
      end
    end

    describe 'PUT appointments' do
      context 'when the appointment is successfully cancelled' do
        # it 'returns a status code of 200 and the cancelled appointment with the updated status' do
        #   VCR.use_cassette('vaos/v2/appointments/cancel_appointments_200', match_requests_on: %i[method uri]) do
        #     put '/vaos/v2/appointments/42081', params: { status: 'cancelled' }, headers: inflection_header
        #     expect(response.status).to eq(200)
        #     expect(json_body_for(response)).to match_camelized_schema('vaos/v2/appointment', { strict: false })
        #     data = JSON.parse(response.body)['data']
        #     expect(data['attributes']['serviceName']).to eq('test_clinic')
        #     expect(data['attributes']['location']).to eq(mock_facility)
        #     expect(data['attributes']['status']).to eq('cancelled')
        #   end
        # end
        it 'returns a 400 status code' do
          VCR.use_cassette('vaos/v2/appointments/cancel_appointment_400', match_requests_on: %i[method path query]) do
            put '/vaos/v2/appointments/42081', params: { status: 'cancelled' }
            expect(response.status).to eq(400)
            expect(JSON.parse(response.body)['errors'][0]['code']).to eq('VAOS_400')
          end
        end
      end

      context 'when the backend service cannot handle the request' do
        it 'returns a 502 status code' do
          VCR.use_cassette('vaos/v2/appointments/cancel_appointment_500', match_requests_on: %i[method path query]) do
            put '/vaos/v2/appointments/35952', params: { status: 'cancelled' }
            expect(response.status).to eq(502)
            expect(JSON.parse(response.body)['errors'][0]['code']).to eq('VAOS_502')
          end
        end
      end
    end
  end
end
