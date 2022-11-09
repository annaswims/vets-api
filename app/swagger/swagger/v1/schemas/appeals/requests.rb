# frozen_string_literal: true

module Swagger
  module V1
    module Schemas
      module Appeals
        class Requests
          include Swagger::Blocks

          swagger_schema :DecisionReviewEvidence do
            property :data, type: :object do
              property :attributes, type: :object do
                key :required, %i[guid]
                property :guid, type: :string, example: '3c05b2f0-0715-4298-965d-f733465ed80a'
              end
              property :id, type: :string, example: '11'
              property :type, type: :string, example: 'decision_review_evidence_attachment'
            end
          end

          swagger_schema :Appeals do
            key :type, :object
            key :required, %i[data]
            property :data, type: :array do
              items type: :object do
              end
            end
          end

          swagger_schema :AppealsErrors do
            key :type, :object
            items do
              key :type, :object
              property :title, type: :string
              property :detail, type: :string
            end
          end
        end
      end
    end
  end
end

