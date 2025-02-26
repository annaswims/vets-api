# frozen_string_literal: true

require 'evss/common_service'

module EVSS
  class UpdateClaimFromRemoteJob
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(user_uuid, claim_id)
      Raven.tags_context(source: 'claims-status')
      user = User.find user_uuid
      claim = EVSSClaim.find claim_id
      auth_headers = EVSS::AuthHeaders.new(user).to_h
      raw_claim = EVSS::ClaimsService.new(
        auth_headers
      ).find_claim_with_docs_by_id(claim.evss_id).body.fetch('claim', {})
      claim.update(data: raw_claim)
      set_status(user_uuid, claim_id, 'SUCCESS')
    rescue
      set_status(user_uuid, claim_id, 'FAILED')
      raise
    end

    private

    def set_status(user_uuid, claim_id, status)
      tracker = EVSSClaimsSyncStatusTracker.find_or_build(user_uuid)
      tracker.claim_id = claim_id
      tracker.set_single_status(status)
    end
  end
end
