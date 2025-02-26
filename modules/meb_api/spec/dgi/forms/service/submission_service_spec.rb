# frozen_string_literal: true

require 'rails_helper'
require 'dgi/forms/service/submission_service'

RSpec.describe MebApi::DGI::Forms::Submission::Service do
  VCR.configure do |config|
    config.filter_sensitive_data('removed') do |interaction|
      if interaction.request.headers['Authorization']
        token = interaction.request.headers['Authorization'].first

        if (match = token.match(/^Bearer.+/) || token.match(/^token.+/))
          match[0]
        end
      end
    end
    let(:user) { FactoryBot.create(:user, :loa3) }
    let(:service) { MebApi::DGI::Forms::Submission::Service.new(user) }
    let(:claimant_params) do
      { form: {
        form_id: 1,
        education_benefit: {
          claimant: {
            first_name: 'Herbert',
            middle_name: 'Hoover',
            last_name: 'Hoover',
            date_of_birth: '1980-03-11',
            contact_info: {
              address_line_1: '503 upper park',
              address_line_2: '',
              city: 'falls church',
              zipcode: '22046',
              email_address: 'hhover@test.com',
              address_type: 'DOMESTIC',
              mobile_phone_number: '4409938894',
              country_code: 'US',
              state_code: 'VA'
            },
            notification_method: 'EMAIL'
          }
        },
        relinquished_benefit: {
          eff_relinquish_date: '2021-10-15',
          relinquished_benefit: 'Chapter30'
        },
        additional_considerations: {
          active_duty_kicker: 'N/A',
          academy_rotc_scholarship: 'YES',
          reserve_kicker: 'N/A',
          senior_rotc_scholarship: 'YES',
          active_duty_dod_repay_loan: 'YES'
        },
        comments: {
          disagree_with_service_period: false
        },
        direct_deposit: {
          direct_deposit_account_number: '**3123123123',
          account_type: 'savings',
          direct_deposit_routing_number: '123123123'
        }
      } }
    end

    let(:dd_params) do
      {
        dposit_acnt_nbr: '9876543211234',
        dposit_acnt_type_nm: 'Checking',
        financial_institution_name: 'Comerica',
        routng_trnsit_nbr: '042102115'
      }
    end

    describe '#submit_toe_claim' do
      let(:faraday_response) { double('faraday_connection') }

      before do
        allow(faraday_response).to receive(:env)
      end

      context 'when successful' do
        it 'returns a status of 200' do
          VCR.use_cassette('dgi/forms/submit_toe_claim') do
            response = service.submit_claim(ActionController::Parameters.new(claimant_params),
                                            ActionController::Parameters.new(dd_params),
                                            'toe')
            expect(response.status).to eq(200)
          end
        end
      end
    end
  end
end
