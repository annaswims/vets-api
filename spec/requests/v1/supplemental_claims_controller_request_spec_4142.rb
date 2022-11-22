# frozen_string_literal: true

require 'rails_helper'
require 'support/controller_spec_helper'

RSpec.describe V1::SupplementalClaimsController do
  let(:user) { build(:user, :loa3) }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }

  before { sign_in_as(user) }

  describe '#create' do
    def personal_information_logs
      PersonalInformationLog.where 'error_class like ?',
                                   'V1::SupplementalClaimsController#create exception % (SC_V1)'
    end

    subject do
      post '/v1/supplemental_claims',
           params: VetsJsonSchema::EXAMPLES.fetch('SC-CREATE-REQUEST-BODY-WITH-4142_V1').to_json,
           headers: headers
    end

    it 'creates a supplemental claim and sends a 4142 form when 4142 info is provided' do
      VCR.use_cassette('decision_review/SC-CREATE-RESPONSE-WITH-4142-200_V1') do
        VCR.use_cassette('central_mail/submit_4142') do 
          pre_existing_generated_files = Dir['tmp/*']
          previous_appeal_submission_ids = AppealSubmission.all.pluck :submitted_appeal_uuid
          subject
          expect(response).to be_successful
          parsed_response = JSON.parse(response.body)
          id = parsed_response['data']['id']
          expect(previous_appeal_submission_ids).not_to include id
          appeal_submission = AppealSubmission.find_by(submitted_appeal_uuid: id)
          expect(appeal_submission.type_of_appeal).to eq('SC')          
          post_existing_files = Dir['tmp/*']
          expect(post_existing_files.count - 1).to eq(pre_existing_generated_files.count)
          generated_file = post_existing_files - pre_existing_generated_files
          expect(MIME::Types.type_for(generated_file).first.content_type).to eq("application/pdf")
        end
      end
    end
  end
end