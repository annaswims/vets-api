# frozen_string_literal: true

module ClaimsApi
  class BGSToLighthouseClaimsMapperService < ClaimsApi::Service
    attr_accessor :bgs_claim, :lighthouse_claim

    def initialize(bgs_claim: nil, lighthouse_claim: nil)
      @bgs_claim        = bgs_claim
      @lighthouse_claim = lighthouse_claim
    end

    def process
      return matched_claim if bgs_and_lighthouse_claims_exist?
      return unmatched_bgs_claim if bgs_claim_only?
      return unmatched_lighthouse_claim if lighthouse_claim_only?

      {}
    end

    private

    def bgs_and_lighthouse_claims_exist?
      bgs_claim.present? && lighthouse_claim.present?
    end

    def bgs_claim_only?
      bgs_claim.present? && lighthouse_claim.blank?
    end

    def lighthouse_claim_only?
      bgs_claim.blank? && lighthouse_claim.present?
    end

    def matched_claim
      # this claim was submitted via Lighthouse, so use the 'id' the user is most likely to know
      { id: lighthouse_claim.id, lighthouseId: lighthouse_claim.id, claimId: lighthouse_claim.evss_id,
        claimType: lighthouse_claim.claim_type }.merge(shared_claim_traits)
    end

    def unmatched_bgs_claim
      { id: bgs_claim[:benefit_claim_id], claimType: bgs_claim[:claim_status_type] }.merge(shared_claim_traits)
    end

    # rubocop:disable Metrics/MethodLength
    def shared_claim_traits
      {
        claim_type: bgs_claim[:claim_status_type],
        lighthouse_id: bgs_claim[:id],
        claimType: bgs_claim[:claim_status_type],
        date_filed: bgs_claim[:claim_dt].present? ? bgs_claim[:claim_dt].strftime('%D') : nil,
        status: bgs_claim[:phase_type],
        contention_list: bgs_claim[:contentions],
        poa: bgs_claim[:poa],
        end_product_code: bgs_claim[:end_product_code],
        documents_needed: map_yes_no_to_boolean('attention_needed', bgs_claim[:attention_needed]),
        waiver_5103_Submitted: map_y_n_to_boolean('filed5103_waiver_ind', bgs_claim[:filed5103_waiver_ind]),
        development_letter_sent: map_yes_no_to_boolean('development_letter_sent', bgs_claim[:development_letter_sent]),
        base_end_prdct_type_cd: bgs_claim[:base_end_prdct_type_cd],
        claim_id: bgs_claim[:benefit_claim_id],
        benefit_claim_type_code: bgs_claim[:bnft_claim_type_cd],
        claim_close_date: bgs_claim[:claim_close_dt],
        claim_complete_date: bgs_claim[:claim_complete_dt],
        claim_status: bgs_claim[:claim_status],
        end_product_type_code: bgs_claim[:end_prdct_type_cd],
        phase_changed_date: bgs_claim[:phase_chngd_dt],
        phase_type: bgs_claim[:phase_type],
        program_type: bgs_claim[:program_type],
        participant_claimant_id: bgs_claim[:ptcpnt_clmant_id],
        participant_vet_id: bgs_claim[:ptcpnt_vet_id],
        appeal_possible: map_yes_no_to_boolean('appeal_possible', bgs_claim[:appeal_possible]),
        decision_letter_sent: map_yes_no_to_boolean('decision_notification_sent',
                                                    bgs_claim[:decision_notification_sent])
      }
    end
    # rubocop:enable Metrics/MethodLength

    def unmatched_lighthouse_claim
      { id: lighthouse_claim.id, lighthouseId: lighthouse_claim.id, claimType: lighthouse_claim.claim_type,
        status: lighthouse_claim.status.capitalize, claimId: lighthouse_claim.evss_id }
    end

    def map_yes_no_to_boolean(key, value)
      # Requested decision appears to be included in the BGS payload
      # only when it is yes. Assume an ommission is akin to no, i.e., false
      return false if value.blank?

      case value.downcase
      when 'yes' then true
      when 'no' then false
      else
        Rails.logger.error "Expected key '#{key}' to be Yes/No. Got '#{s}'."
        nil
      end
    end

    def map_y_n_to_boolean(key, value)
      return nil if value.blank?

      case value.downcase
      when 'y' then true
      when 'n' then false
      else
        Rails.logger.error "Expected key '#{key}' to be Y/N. Got '#{s}'."
        nil
      end
    end
  end
end
