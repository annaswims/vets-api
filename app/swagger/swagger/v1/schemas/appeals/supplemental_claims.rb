# frozen_string_literal: true

require 'decision_review/schemas'
module Swagger
  module V1
    module Schemas
      module Appeals
        class SupplementalClaims
          include Swagger::Blocks

          VetsJsonSchema::SCHEMAS.fetch('SC-CREATE-REQUEST-BODY_V1')['definitions'].each do |k, v|
            if k == 'scCreate'
              # remove draft-07 specific schema items, they won't validate with swagger
              attrs = v['properties']['data']['properties']['attributes']
              attrs['properties']['veteran']['properties']['timezone'].delete('$comment')
              attrs['properties']['veteran'].delete('if')
              attrs['properties']['veteran'].delete('then')
              attrs.delete('if')
              attrs.delete('then')
            end
            swagger_schema k, v
          end

          swagger_schema 'scCreate' do
            example JSON.parse(File.read('spec/fixtures/supplemental_claims/valid_SC_create_request_V1.json'))
          end

          VetsJsonSchema::SCHEMAS.fetch('SC-SHOW-RESPONSE-200_V1')['definitions'].each do |k, v|
            swagger_schema(k == 'root' ? 'scShowRoot' : k, v) {}
          end

          swagger_schema 'scShowRoot' do
            example JSON.parse(File.read('spec/fixtures/supplemental_claims/SC_show_response_200_V1.json'))
          end

          swagger_schema 'scContestableIssues' do
            example JSON.parse(
              File.read(
                'spec/fixtures/supplemental_claims/SC_contestable_issues_response_200_V1.json'
              )
            )
          end
        end
      end
    end
  end
end
