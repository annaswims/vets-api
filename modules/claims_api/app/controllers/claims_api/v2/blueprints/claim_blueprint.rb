# frozen_string_literal: true

module ClaimsApi
  module V2
    module Blueprints
      class ClaimBlueprint < Blueprinter::Base
        identifier :id

        field :@links do |claim, options|
          {
            rel: 'self',
            type: 'GET',
            url: "#{options[:base_url]}/services/benefits/v2/veterans/#{options[:veteran_id]}/claims/#{claim[:id]}"
          }
        end

        field :lighthouse_id
        field :contention_list
        field :date_filed
        field :decision_letter_sent
        field :development_letter_sent
        field :documents_needed
        field :end_product_code
        field :requested_decision
        field :status
        field :claim_type
        field :type
        field :base_end_prdct_type_cd
        field :claim_id
        field :bnft_claim_type_cd
        field :claim_close_dt
        field :claim_complete_dt
        field :claim_status
        field :phase_type
        field :program_type
        field :ptcpnt_clmant_id
        field :ptcpnt_vet_id
        field :appeal_possible
        field :supporting_documents do |claim, _options|
          auto_established_claim = ClaimsApi::AutoEstablishedClaim.find_by evss_id: claim[:id]
          if auto_established_claim.present?
            auto_established_claim.supporting_documents.map do |document|
              {
                id: document.id,
                md5: if document.file_data['filename'].present?
                       Digest::MD5.hexdigest(document.file_data['filename'])
                     else
                       ''
                     end,
                filename: document.file_data['filename'],
                uploaded_at: document.created_at
              }
            end
          else
            []
          end
        end
        field :type

        transform ClaimsApi::V2::Blueprints::Transformers::LowerCamelTransformer

        view :list do
          exclude :contention_list
          exclude :end_product_code
          exclude :supporting_documents
          exclude :poa
          exclude :appeal_possible
          exclude :base_end_prdct_type_cd
          exclude :bnft_claim_type_cd
          exclude :claim_close_dt
          exclude :claim_complete_dt
          exclude :claim_id
          exclude :claim_status
          exclude :claim_type
          exclude :lighthouse_id
          exclude :phase_type
          exclude :ptcpnt_clmant_id
          exclude :ptcpnt_vet_id
          exclude :program_type
          exclude :type

          transform ClaimsApi::V2::Blueprints::Transformers::LowerCamelTransformer
        end
      end
    end
  end
end
