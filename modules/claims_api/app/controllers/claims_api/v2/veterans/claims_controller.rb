# frozen_string_literal: true

require 'claims_api/bgs_claim_status_mapper'
require 'claims_api/v2/mock_documents_service'

module ClaimsApi
  module V2
    module Veterans
      class ClaimsController < ClaimsApi::V2::ApplicationController
        before_action :verify_access!

        def index
          bgs_claims = bgs_service.ebenefits_benefit_claims_status.find_benefit_claims_status_by_ptcpnt_id(
            participant_id: target_veteran.participant_id
          )
          lighthouse_claims = ClaimsApi::AutoEstablishedClaim.where(veteran_icn: target_veteran.mpi.icn)

          render json: [] && return unless bgs_claims || lighthouse_claims
          mapped_claims = map_claims(bgs_claims: bgs_claims, lighthouse_claims: lighthouse_claims)

          blueprint_options = { base_url: request.base_url, veteran_id: params[:veteranId], view: :list }
          render json: ClaimsApi::V2::Blueprints::ClaimBlueprint.render(mapped_claims, blueprint_options)
        end

        def show
          lighthouse_claim = find_lighthouse_claim!(claim_id: params[:id])
          benefit_claim_id = lighthouse_claim.present? ? lighthouse_claim.evss_id : params[:id]
          bgs_claim = find_bgs_claim!(claim_id: benefit_claim_id)

          if lighthouse_claim.blank? && bgs_claim.blank?
            raise ::Common::Exceptions::ResourceNotFound.new(detail: 'Claim not found')
          end

          output = generate_show_output(bgs_claim: bgs_claim, lighthouse_claim: lighthouse_claim)
          blueprint_options = { base_url: request.base_url, veteran_id: params[:veteranId] }

          render json: ClaimsApi::V2::Blueprints::ClaimBlueprint.render(output, blueprint_options)
        end

        private

        def bgs_service
          BGS::Services.new(external_uid: target_veteran.participant_id,
                            external_key: target_veteran.participant_id)
        end

        def evss_docs_service
          EVSS::DocumentsService.new(auth_headers)
        end

        def generate_show_output(bgs_claim:, lighthouse_claim:) # rubocop:disable Metrics/MethodLength
          if lighthouse_claim.present? && bgs_claim.present?
            bgs_details = bgs_claim[:benefit_claim_details_dto]
            structure = build_claim_structure(
              data: bgs_details,
              lighthouse_id: lighthouse_claim.id,
              upstream_id: bgs_details[:benefit_claim_id]
            )
          elsif lighthouse_claim.present? && bgs_claim.blank?
            structure = {
              lighthouse_id: lighthouse_claim.id,
              type: lighthouse_claim.claim_type,
              status: lighthouse_claim.status.capitalize
            }
          else
            bgs_details = bgs_claim[:benefit_claim_details_dto]
            structure = build_claim_structure(data: bgs_details,
                                              lighthouse_id: nil,
                                              upstream_id: bgs_details[:benefit_claim_id])
          end
          structure.merge!(errors: get_errors(lighthouse_claim))
          structure.merge!(supporting_documents: build_supporting_docs(bgs_claim))
          structure.merge!(tracked_items: map_bgs_tracked_items(bgs_claim))
          structure.merge!(build_claim_phase_attributes(bgs_claim, 'show'))
        end

        def map_claims(bgs_claims:, lighthouse_claims:) # rubocop:disable Metrics/MethodLength
          mapped_claims = bgs_claims[:benefit_claims_dto][:benefit_claim].map do |bgs_claim|
            matching_claim = find_bgs_claim_in_lighthouse_collection(
              lighthouse_collection: lighthouse_claims,
              bgs_claim: bgs_claim
            )
            if matching_claim
              lighthouse_claims.delete(matching_claim)
              build_claim_structure(
                data: bgs_claim,
                lighthouse_id: matching_claim.id,
                upstream_id: bgs_claim[:benefit_claim_id]
              )
            else
              build_claim_structure(data: bgs_claim, lighthouse_id: nil, upstream_id: bgs_claim[:benefit_claim_id])
            end
          end

          lighthouse_claims.each do |remaining_claim|
            # if claim wasn't matched earlier, then this claim is in a weird state where
            #  it's 'established' in Lighthouse, but unknown to BGS.
            #  shouldn't really ever happen, but if it does, skip it.
            next if remaining_claim.status.casecmp?('established')

            mapped_claims << {
              lighthouse_id: remaining_claim.id,
              type: remaining_claim.claim_type,
              status: remaining_claim.status.capitalize
            }
          end

          mapped_claims
        end

        def find_bgs_claim_in_lighthouse_collection(lighthouse_collection:, bgs_claim:)
          # EVSS and BGS use the same ID to refer to a claim, hence the following
          # search condition to see if we've stored the same claim in vets-api
          lighthouse_collection.find do |lighthouse_claim|
            lighthouse_claim.evss_id.to_s == bgs_claim[:benefit_claim_id]
          end
        end

        def find_lighthouse_claim!(claim_id:)
          lighthouse_claim = ClaimsApi::AutoEstablishedClaim.get_by_id_and_icn(claim_id, target_veteran.mpi.icn)

          if looking_for_lighthouse_claim?(claim_id: claim_id) && lighthouse_claim.blank?
            raise ::Common::Exceptions::ResourceNotFound.new(detail: 'Claim not found')
          end

          lighthouse_claim
        end

        def find_bgs_claim!(claim_id:)
          return if claim_id.blank?

          bgs_service.ebenefits_benefit_claims_status.find_benefit_claim_details_by_benefit_claim_id(
            benefit_claim_id: claim_id
          )
        rescue Savon::SOAPFault => e
          # the ebenefits service raises an exception if a claim is not found,
          # so catch the exception here and return a 404 instead
          if e.message.include?("No BnftClaim found for #{claim_id}")
            raise ::Common::Exceptions::ResourceNotFound.new(detail: 'Claim not found')
          end

          raise
        end

        def looking_for_lighthouse_claim?(claim_id:)
          claim_id.to_s.include?('-')
        end

        def build_claim_structure(data:, lighthouse_id:, upstream_id:) # rubocop:disable Metrics/MethodLength
          {
            claim_date: data[:claim_dt].present? ? data[:claim_dt].strftime('%D') : nil,
            claim_id: upstream_id,
            claim_phase_dates: build_claim_phase_attributes(data, 'index'),
            claim_type_code: data[:bnft_claim_type_cd],
            claim_type: data[:claim_status_type],
            contention_list: data[:contentions]&.split(','),
            decision_letter_sent: map_yes_no_to_boolean('decision_notification_sent',
                                                        data[:decision_notification_sent]),
            development_letter_sent: map_yes_no_to_boolean('development_letter_sent', data[:development_letter_sent]),
            documents_needed: map_yes_no_to_boolean('attention_needed', data[:attention_needed]),
            end_product_code: data[:end_prdct_type_cd],
            evidence_waiver_submitted_5103: map_yes_no_to_boolean('filed5103_waiver_ind', data[:filed5103_waiver_ind]),
            jurisdiction: data[:regional_office_jrsdctn],
            lighthouse_id: lighthouse_id,
            max_est_claim_date: data[:max_est_claim_complete_dt],
            min_est_claim_date: data[:min_est_claim_complete_dt],
            status: detect_status(data),
            submitter_application_code: data[:submtr_applcn_type_cd],
            submitter_role_code: data[:submtr_role_type_cd],
            temp_jurisdiction: data[:temp_regional_office_jrsdctn]
          }
        end

        def get_phase_type_indicator_array(data)
          return if data[:benefit_claim_details_dto][:phase_type_change_ind].nil?

          data = data[:benefit_claim_details_dto][:phase_type_change_ind]
          data.split('')
        end

        def get_bgs_phase_name(data, phase_number)
          ClaimsApi::BGSClaimStatusMapper.new(data[:benefit_claim_details_dto], phase_number).name_from_phase
        end

        def current_phase_back(data)
          return false if data[:benefit_claim_details_dto][:phase_type_change_ind].nil?

          pt_ind_array = get_phase_type_indicator_array(data)
          pt_ind_array.first.to_i > pt_ind_array.last.to_i
        end

        def latest_phase_type(data)
          return if data[:benefit_claim_details_dto][:phase_type_change_ind].nil?

          if !data[:benefit_claim_details_dto][:phase_type].nil?
            data[:benefit_claim_details_dto][:phase_type]
          else
            pt_ind_array = get_phase_type_indicator_array(data)
            claim = get_bgs_phase_name(data, pt_ind_array.last.to_i)
            claim.bgs_status_from_phase(pt_ind_array.last.to_i)
          end
        end

        def format_bgs_phase_chng_dates(data)
          if data[:phase_chngd_dt].nil? &&
             (data[:benefit_claim_details_dto].nil? || data[:benefit_claim_details_dto][:phase_chngd_dt].nil?)
            return
          end

          phase_change_date = data[:phase_chngd_dt] || data[:benefit_claim_details_dto][:phase_chngd_dt]
          d = Date.parse(phase_change_date.to_s)
          d.strftime('%Y-%m-%d')
        end

        def detect_status(data)
          return data[:phase_type] if data.key?(:phase_type)

          cast_claim_lc_status(data[:bnft_claim_lc_status])
        end

        def get_errors(lighthouse_claim)
          return [] if lighthouse_claim.blank? || lighthouse_claim.evss_response.blank?

          lighthouse_claim.evss_response.map do |error|
            {
              detail: "#{error['severity']} #{error['detail'] || error['text']}".squish,
              source: error['key'] ? error['key'].gsub('.', '/') : error['key']
            }
          end
        end

        # The status can either be an object or array
        # This picks the most recent status from the array
        def cast_claim_lc_status(status)
          return if status.blank?

          stat = [status].flatten.max_by do |t|
            t[:phase_chngd_dt]
          end
          stat[:phase_type]
        end

        def map_yes_no_to_boolean(key, value)
          # Requested decision appears to be included in the BGS payload
          # only when it is yes. Assume an ommission is akin to no, i.e., false
          return false if value.blank?

          case value.downcase
          when 'yes', 'y' then true
          when 'no', 'n' then false
          else
            Rails.logger.error "Expected key '#{key}' to be Yes/No. Got '#{s}'."
            nil
          end
        end

        def map_bgs_tracked_items(bgs_claim) # rubocop:disable Metrics/MethodLength
          return [] if bgs_claim.nil?

          claim_id = bgs_claim.dig(:benefit_claim_details_dto, :benefit_claim_id)
          return [] if claim_id.nil?

          tracked_items = bgs_service
                          .tracked_items
                          .find_tracked_items(claim_id)
                          .dig(:benefit_claim, :dvlpmt_items) || []
          ebenefits_details = bgs_claim[:benefit_claim_details_dto]

          # Just in case there's a doc in ebenefits that we don't have a tracked_item for
          ids = tracked_items.pluck(:dvlpmt_item_id)
          docs = (
            (ebenefits_details[:wwsnfy] || []) +
            (ebenefits_details[:wwr] || []) +
            (ebenefits_details[:wwd] || [])
          )
          ids += docs.pluck(:dvlpmt_item_id)
          ids = ids.uniq

          ids.map.with_index do |id, i|
            item = tracked_items.find { |t| t[:dvlpmt_item_id] == id } || {}
            detail = docs.find do |doc|
              doc[:dvlpmt_item_id] == id
            end || {}

            # Values for status enum: "ACCEPTED",
            # "INITIAL_REVIEW_COMPLETE",
            # "NEEDED",
            # "NO_LONGER_REQUIRED"
            # "SUBMITTED_AWAITING_REVIEW",

            if detail[:date_rcvd].nil?
              status = 'NEEDED'
            else
              status = 'SUBMITTED_AWAITING_REVIEW'

              if item.present?
                claim_status = bgs_claim.dig(:benefit_claim_details_dto, :bnft_claim_lc_status).max do |stat|
                  stat[:phase_chngd_dt]
                end
                status = if ['Preparation for Decision',
                             'Pending Decision Approval',
                             'Preparation for Notification',
                             'Complete'].include? claim_status
                           'ACCEPTED'
                         else
                           'INITIAL_REVIEW_COMPLETE'
                         end
              end
            end

            uploads_allowed = ['NEEDED", "SUBMITTED_AWAITING_REVIEW", "INITIAL_REVIEW_COMPLETE']
                              .include? status ? true : false

            {
              closed_date: detail[:date_closed]&.iso8601,
              description: detail[:items],
              displayed_name: "Request #{i + 1}", # +1 given a 1 index'd array
              dvlpmt_tc: item[:dvlpmt_tc],
              opened_date: detail[:date_open]&.iso8601,
              overdue: item[:suspns_dt].nil? ? false : item[:suspns_dt] < Time.zone.now, # EVSS generates this field
              requested_date: item[:req_dt]&.iso8601,
              suspense_date: item[:suspns_dt]&.iso8601,
              tracked_item_id: id.to_i,
              tracked_item_status: status, # EVSS generates this field
              uploaded: !detail[:date_rcvd].nil?, # EVSS generates this field
              uploads_allowed: uploads_allowed # EVSS generates this field
            }
          end
        end

        def build_supporting_docs(bgs_claim)
          return [] if bgs_claim.nil?

          docs = if sandbox?
                   { documents: ClaimsApi::V2::MockDocumentsService.new.generate_documents }.with_indifferent_access
                 else
                   evss_docs_service.get_claim_documents(bgs_claim[:benefit_claim_details_dto][:benefit_claim_id]).body
                 end
          return [] if docs.nil? || docs['documents'].blank?

          docs['documents'].map do |doc|
            {
              document_id: doc['document_id'],
              document_type_label: doc['document_type_label'],
              original_file_name: doc['original_file_name'],
              tracked_item_id: doc['tracked_item_id'],
              upload_date: doc['upload_date']
            }
          end
        end

        def build_claim_phase_attributes(bgs_claim, view)
          return {} if bgs_claim.nil?

          case view
          when 'show'
            {
              claim_phase_dates:
                {
                  phase_change_date: format_bgs_phase_chng_dates(bgs_claim),
                  current_phase_back: current_phase_back(bgs_claim),
                  latest_phase_type: latest_phase_type(bgs_claim)
                }
            }
          when 'index'
            {
              phase_change_date: format_bgs_phase_chng_dates(bgs_claim)
            }
          end
        end

        def sandbox?
          Settings.claims_api.claims_error_reporting.environment_name&.downcase.eql? 'sandbox'
        end
      end
    end
  end
end
