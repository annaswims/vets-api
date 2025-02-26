# frozen_string_literal: true

require 'swagger_helper'
require 'rails_helper'
require_relative '../../../support/swagger_shared_components/v2'

# doc generation for V2 ITFs temporarily disabled by API-13879
describe 'IntentToFile', swagger_doc: Rswag::TextHelpers.new.claims_api_docs,
                         document: false do
  path '/veterans/{veteranId}/intent-to-files/{type}' do
    get "Returns last active Intent to File form submission for given 'type'." do
      tags 'Intent to File'
      operationId 'active0966itf'
      security [
        { productionOauth: ['claim.read'] },
        { sandboxOauth: ['claim.read'] },
        { bearer_token: [] }
      ]
      produces 'application/json'
      description "Returns Veteran's last active Intent to File submission for given 'type'."

      parameter name: 'veteranId',
                in: :path,
                required: true,
                type: :string,
                description: 'ID of Veteran'
      parameter name: 'type',
                in: :path,
                required: true,
                type: :string,
                description: 'Type of Intent to File to return. Available values - compensation, pension, burial'
      let(:veteranId) { '1013062086V794840' } # rubocop:disable RSpec/VariableName
      let(:type) { 'compensation' }
      let(:Authorization) { 'Bearer token' }

      describe 'Getting a successful response' do
        response '200', 'Successful response with active Intent to File' do
          schema JSON.parse(
            File.read(
              Rails.root.join(
                'spec', 'support', 'schemas', 'claims_api', 'v2', 'veterans', 'intent_to_files', 'intent_to_file.json'
              )
            )
          )

          let(:bgs_response) do
            JSON.parse(
              File.read(
                Rails.root.join('modules', 'claims_api', 'spec', 'fixtures', 'v2', 'veterans', 'intent_to_files',
                                'find_by_ptcpnt_id_and_itf_type.json')
              ),
              symbolize_names: true
            )
          end
          let(:scopes) { %w[claim.read] }

          before do |example|
            Timecop.freeze(Time.zone.parse('2022-01-01T08:00:00Z'))

            with_okta_user(scopes) do
              expect_any_instance_of(BGS::IntentToFileWebService)
                .to receive(:find_intent_to_file_by_ptcpnt_id_itf_type_cd).and_return(bgs_response)

              submit_request(example.metadata)
            end
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
            Timecop.return
          end

          it 'returns a valid 200 response' do |example|
            assert_response_matches_metadata(example.metadata)
          end
        end
      end

      describe 'Getting a 401 response' do
        response '401', 'Unauthorized' do
          schema JSON.parse(File.read(Rails.root.join('spec', 'support', 'schemas', 'claims_api', 'v2', 'errors',
                                                      'default.json')))

          let(:scopes) { %w[claim.read] }

          before do |example|
            submit_request(example.metadata)
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end

          it 'returns a 401 response' do |example|
            assert_response_matches_metadata(example.metadata)
          end
        end
      end

      describe 'Getting a 403 response' do
        response '403', 'Forbidden' do
          schema JSON.parse(File.read(Rails.root.join('spec', 'support', 'schemas', 'claims_api', 'v2', 'errors',
                                                      'default.json')))

          let(:veteran) { OpenStruct.new(mpi: nil, participant_id: nil) }
          let(:scopes) { %w[claim.read] }

          before do |example|
            with_okta_user(scopes) do
              expect(ClaimsApi::Veteran).to receive(:new).and_return(veteran)

              submit_request(example.metadata)
            end
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end

          it 'returns a 403 response' do |example|
            assert_response_matches_metadata(example.metadata)
          end
        end
      end

      describe 'Getting a 404 response' do
        response '404', 'Resource not found' do
          schema JSON.parse(
            File.read(
              Rails.root.join('spec', 'support', 'schemas', 'claims_api', 'v2', 'errors', 'default.json')
            )
          )
          let(:scopes) { %w[claim.read] }

          before do |example|
            with_okta_user(scopes) do
              expect_any_instance_of(BGS::IntentToFileWebService)
                .to receive(:find_intent_to_file_by_ptcpnt_id_itf_type_cd).and_return(nil)

              submit_request(example.metadata)
            end
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end

          it 'returns a 404 response' do |example|
            assert_response_matches_metadata(example.metadata)
          end
        end
      end
    end
  end

  path '/veterans/{veteranId}/intent-to-files' do
    post 'Submit form 0966 Intent to File.' do
      tags 'Intent to File'
      operationId 'post0966itf'
      security [
        { productionOauth: ['claim.read', 'claim.write'] },
        { sandboxOauth: ['claim.read', 'claim.write'] },
        { bearer_token: [] }
      ]
      consumes 'application/json'
      produces 'application/json'
      description 'Establishes an intent to file for disability compensation and pension claims.'

      parameter name: 'veteranId',
                in: :path,
                required: true,
                type: :string,
                description: 'ID of Veteran'
      let(:veteranId) { '1013062086V794840' } # rubocop:disable RSpec/VariableName
      let(:type) { 'compensation' }
      let(:Authorization) { 'Bearer token' }
      parameter SwaggerSharedComponents::V2.body_examples[:intent_to_file]

      describe 'Getting a successful response' do
        response '200', '0966 Response' do
          schema JSON.parse(
            File.read(
              Rails.root.join(
                'spec', 'support', 'schemas', 'claims_api', 'v2', 'veterans', 'intent_to_files', 'intent_to_file.json'
              )
            )
          )

          let(:scopes) { %w[claim.write] }
          let(:data) do
            {
              type: 'compensation'
            }
          end
          let(:stub_response) do
            {
              intent_to_file_id: '1',
              create_dt: Time.zone.now.to_date,
              exprtn_dt: Time.zone.now.to_date + 1.year,
              itf_status_type_cd: 'Active',
              itf_type_cd: 'C'
            }
          end

          before do |example|
            allow_any_instance_of(BGS::IntentToFileWebService).to receive(:insert_intent_to_file).and_return(
              stub_response
            )

            with_okta_user(scopes) do
              submit_request(example.metadata)
            end
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end

          it 'returns a valid 200 response' do |example|
            assert_response_matches_metadata(example.metadata)
          end
        end
      end

      describe 'Getting a 400 response' do
        response '400', 'Bad Request' do
          schema JSON.parse(File.read(Rails.root.join('spec', 'support', 'schemas', 'claims_api', 'v2', 'errors',
                                                      'default.json')))

          let(:scopes) { %w[claim.write] }
          let(:data) do
            {
              type: 'some-invalid-value'
            }
          end

          before do |example|
            with_okta_user(scopes) do
              submit_request(example.metadata)
            end
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end

          it 'returns a valid 400 response' do |example|
            assert_response_matches_metadata(example.metadata)
          end
        end
      end

      describe 'Getting a 401 response' do
        response '401', 'Unauthorized' do
          schema JSON.parse(File.read(Rails.root.join('spec', 'support', 'schemas', 'claims_api', 'v2', 'errors',
                                                      'default.json')))

          let(:scopes) { %w[claim.write] }
          let(:data) do
            {
              type: 'compensation'
            }
          end

          before do |example|
            submit_request(example.metadata)
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end

          it 'returns a valid 401 response' do |example|
            assert_response_matches_metadata(example.metadata)
          end
        end
      end

      describe 'Getting a 403 response' do
        let(:veteranId) { 'not-the-same-id-as-tamara' } # rubocop:disable RSpec/VariableName

        response '403', 'Forbidden' do
          schema JSON.parse(File.read(Rails.root.join('spec', 'support', 'schemas', 'claims_api', 'v2', 'errors',
                                                      'default.json')))

          let(:scopes) { %w[claim.write] }
          let(:data) do
            {
              type: 'compensation'
            }
          end

          before do |example|
            with_okta_user(scopes) do
              submit_request(example.metadata)
            end
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end

          it 'returns a valid 403 response' do |example|
            assert_response_matches_metadata(example.metadata)
          end
        end
      end
    end
  end
end
