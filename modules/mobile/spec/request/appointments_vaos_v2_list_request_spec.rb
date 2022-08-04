# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/iam_session_helper'
require_relative '../support/matchers/json_schema_matcher'

RSpec.describe 'appointments', type: :request do
  include JsonSchemaMatchers

  before do
    iam_sign_in(build(:iam_user))
    allow_any_instance_of(IAMUser).to receive(:icn).and_return('1012846043V576341')
    allow_any_instance_of(VAOS::UserService).to receive(:session).and_return('stubbed_token')
    Flipper.enable(:mobile_appointment_requests)
    Flipper.enable(:mobile_appointment_use_VAOS_MFS)
  end

  before(:all) do
    @original_cassette_dir = VCR.configure(&:cassette_library_dir)
    VCR.configure { |c| c.cassette_library_dir = 'modules/mobile/spec/support/vcr_cassettes' }
  end

  after(:all) { VCR.configure { |c| c.cassette_library_dir = @original_cassette_dir } }

  describe 'GET /mobile/v0/appointments' do
    before do
      Timecop.freeze(Time.zone.parse('2022-01-01T19:25:00Z'))
    end

    after { Timecop.return }

    context "requests a list of appointments with" do
      it 'returns VA booked appointment' do
        VCR.use_cassette('appointments/v0/get_va_booked_appointment', match_requests_on: %i[method uri]) do
          get '/mobile/v0/appointments', headers: iam_headers, params: params
        end
        binding.pry
        response_v0 = response.parsed_body

        Flipper.enable(:mobile_appointment_use_VAOS_v2)

        VCR.use_cassette('appointments/get_va_booked_appointment', match_requests_on: %i[method uri]) do
          VCR.use_cassette('appointments/get_facility_clinics_200', match_requests_on: %i[method uri]) do
            VCR.use_cassette('appointments/VAOS_v2/get_facility_200', match_requests_on: %i[method uri]) do
              VCR.use_cassette('appointments/VAOS_v2/mobile_ppms_service/get_provider_200',
                               match_requests_on: %i[method uri]) do
                get '/mobile/v0/appointments', headers: iam_headers, params: params
              end
            end
          end
        end

        response_v2 = response.parsed_body

        expect(response_v0).to eq(response_v2)
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
end
