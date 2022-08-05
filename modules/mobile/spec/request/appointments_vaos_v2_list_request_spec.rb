# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/iam_session_helper'
require_relative '../support/matchers/json_schema_matcher'

RSpec.describe 'appointments', type: :request do
  include JsonSchemaMatchers
  mock_clinic = {
    service_name: 'Friendly Name Optometry'
  }

  mock_facility = { id: '442',
                    name: 'Cheyenne VA Medical Center',
                    physical_address: { type: 'physical',
                                        line: ['2360 East Pershing Boulevard'],
                                        city: 'Cheyenne',
                                        state: 'WY',
                                        postal_code: '82001-5356' },
                    lat: 41.148026,
                    long: -104.786255,
                    phone: { main: '307-778-7550' },
                    url: nil,
                    code: nil }
  before do
    iam_sign_in(build(:iam_user))
    allow_any_instance_of(IAMUser).to receive(:icn).and_return('1012846043V576341')
    allow_any_instance_of(VAOS::UserService).to receive(:session).and_return('stubbed_token')
    allow_any_instance_of(Mobile::V2::Appointments::Proxy).to receive(:get_facility).and_return(mock_facility)
    allow_any_instance_of(Mobile::V2::Appointments::Proxy).to receive(:get_clinic).and_return(mock_clinic)
  end

  before(:all) do
    @original_cassette_dir = VCR.configure(&:cassette_library_dir)
    VCR.configure { |c| c.cassette_library_dir = 'modules/mobile/spec/support/vcr_cassettes' }
  end

  after(:all) { VCR.configure { |c| c.cassette_library_dir = @original_cassette_dir } }

  describe 'GET /mobile/v0/appointments' do
    before do
      Flipper.enable(:mobile_appointment_use_VAOS_v2)

      Timecop.freeze(Time.zone.parse('2022-01-01T19:25:00Z'))
    end

    after do
      Flipper.disable(:mobile_appointment_use_VAOS_v2)

      Timecop.return
    end

    let(:start_date) { Time.zone.parse('2021-01-01T00:00:00Z').iso8601 }
    let(:end_date) { Time.zone.parse('2023-01-01T00:00:00').iso8601 }
    let(:params) { { startDate: start_date, endDate: end_date } }

    # let!(:appointment_v0_cancelled) do

    context 'request VAOS v2 VA cancelled appointment' do
      it 'returned appointment is identical to VAOS v0 version' do
        VCR.use_cassette('appointments/VAOS_v2/get_appointment_200_va_cancelled',
                         match_requests_on: %i[method uri]) do
          get '/mobile/v0/appointments', headers: iam_headers, params: params
        end
        appointment_v0_cancelled = JSON.parse(File.read(Rails.root.join('modules', 'mobile', 'spec', 'support',
                                                                        'fixtures', 'va_v0_cancelled_appointment.json')))
        response_v2 = response.parsed_body.dig('data', 0)

        #Ids will be different due to coming from different Backend systems, so only need to compare attributes
        expect(response_v2['attributes']).to eq(appointment_v0_cancelled['attributes'])
      end
    end

    context 'request VAOS v2 CC Booked appointment' do
      it 'returned appointment is identical to VAOS v0 version' do
        VCR.use_cassette('appointments/VAOS_v2/get_appointment_200_cc_booked',
                         match_requests_on: %i[method uri]) do
          get '/mobile/v0/appointments', headers: iam_headers, params: params
        end
        appointment_v0_cancelled = JSON.parse(File.read(Rails.root.join('modules', 'mobile', 'spec', 'support',
                                                                        'fixtures', 'va_v0_cancelled_appointment.json')))
        response_v2 = response.parsed_body.dig('data', 0)

        #Ids will be different due to coming from different Backend systems, so only need to compare attributes
        expect(response_v2['attributes']).to eq(appointment_v0_cancelled['attributes'])
      end
    end
  end

  #
  # let(:start_date) { Time.zone.parse('2021-01-01T00:00:00Z').iso8601 }
  # let(:end_date) { Time.zone.parse('2023-01-01T00:00:00').iso8601 }
  # let(:params) { { startDate: start_date, endDate: end_date } }
  #
  # context 'requests a list of appointments' do
  #   it 'has access and returns va appointments and honors includes' do
  #     VCR.use_cassette('appointments/VAOS_v2/get_appointments_200', match_requests_on: %i[method uri]) do
  #       VCR.use_cassette('appointments/get_facility_clinics_200', match_requests_on: %i[method uri]) do
  #         VCR.use_cassette('appointments/VAOS_v2/get_facility_200', match_requests_on: %i[method uri]) do
  #           VCR.use_cassette('appointments/VAOS_v2/mobile_ppms_service/get_provider_200', match_requests_on: %i[method uri]) do
  #               get '/mobile/v0/appointments', headers: iam_headers, params: params
  #             end
  #           end
  #         end
  #       end
  #     binding.pry
  #     data = JSON.parse(response.body)['data']
  #     expect(response).to have_http_status(:ok)
  #     expect(response.body).to be_a(String)
  #     expect(data.size).to eq(23)
  #     expect(data[0]['attributes']['serviceName']).to eq('service_name')
  #     expect(data[0]['attributes']['physicalLocation']).to eq('physical_location')
  #     expect(data[0]['attributes']['location']).to eq(mock_facility)
  #     expect(response).to match_camelized_response_schema('vaos/v2/appointments', { strict: false })
  #   end
  # end
end
