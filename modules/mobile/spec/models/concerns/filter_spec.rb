# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/iam_session_helper'

describe Mobile::V0::Concerns::Filter, type: :request do
  let(:user) { build :user }

  before(:all) do
    @original_cassette_dir = VCR.configure(&:cassette_library_dir)
    VCR.configure { |c| c.cassette_library_dir = 'modules/mobile/spec/support/vcr_cassettes' }
  end

  after(:all) { VCR.configure { |c| c.cassette_library_dir = @original_cassette_dir } }

  before do
    allow_any_instance_of(IAMUser).to receive(:icn).and_return('24811694708759028')
    iam_sign_in(build(:iam_user))
    allow_any_instance_of(VAOS::UserService).to receive(:session).and_return('stubbed_token')
    Flipper.disable(:mobile_appointment_requests)
    Flipper.disable(:mobile_appointment_use_VAOS_MFS)
    Flipper.disable(:mobile_appointment_use_VAOS_v2)
  end

  before do
    Timecop.freeze(Time.zone.parse('2020-11-01T10:30:00Z'))
  end

  after { Timecop.return }

  describe '.filter' do

    let(:filters) { { healthcare_provider: 'Joseph Murphy', healthcare_service: 'Audiology Center'} }
    let(:params) { { page: { number: 1, size: 10 }, useCache: false, filter: filters } }
    let(:parsed_body) { JSON.parse(response.body) }

    context 'filter does not exist on model' do
      let(:filters) {{ street_name: 'Professor Bigglesworth' }}

      it 'raises an error' do
        VCR.use_cassette('appointments/get_facilities', match_requests_on: %i[method uri]) do
          VCR.use_cassette('appointments/get_cc_appointments_default', match_requests_on: %i[method uri]) do
            VCR.use_cassette('appointments/get_appointments_default', match_requests_on: %i[method uri]) do
              get '/mobile/v0/appointments', headers: iam_headers, params: params
            end
          end
        end
        expect(parsed_body['errors'].first['meta']['exception']).to eq('NOT FILTERABLE')
      end
    end

    context 'bad filter type' do
      let(:filters) {{ healthcare_provider: [:foo, :bar] }}
      it 'raises an error if the filter is not a string or integer' do
        VCR.use_cassette('appointments/get_facilities', match_requests_on: %i[method uri]) do
          VCR.use_cassette('appointments/get_cc_appointments_default', match_requests_on: %i[method uri]) do
            VCR.use_cassette('appointments/get_appointments_default', match_requests_on: %i[method uri]) do
              get '/mobile/v0/appointments', headers: iam_headers, params: params
            end
          end
        end
        expect(parsed_body['errors'].first['meta']['exception']).to eq('BAD FILTERS')
      end
    end

    it 'returns only the matching records' do
      VCR.use_cassette('appointments/get_facilities', match_requests_on: %i[method uri]) do
        VCR.use_cassette('appointments/get_cc_appointments_default', match_requests_on: %i[method uri]) do
          VCR.use_cassette('appointments/get_appointments_default', match_requests_on: %i[method uri]) do
            get '/mobile/v0/appointments', headers: iam_headers, params: params
          end
        end
      end
      expect(parsed_body['data'].collect{ |d| d['id']}).to eq(['8a488e986bb064d7016bb429f6260012'])
    end

    it 'handles andEquals' do

    end
  end
end
