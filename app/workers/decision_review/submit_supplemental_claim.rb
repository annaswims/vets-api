# frozen_string_literal: true

require 'decision_review/service'

module DecisionReview
  class SubmitSupplementalClaim
    include Sidekiq::Worker
    STATSD_KEY_PREFIX = 'worker.decision_review.submit_supplemental_claim'

    sidekiq_options retry: 15

    # Make a request to lighthosue to submit supplemental claim
    #
    # @param supplemental_claim_submission_uuid [String] The supplemental claim uuid

    def perform(supplemental_claim_submission_uuid)
      # TODO: Figure out what tag to put here
      # Raven.tags_context(source: '10182-board-appeal')
      supplemental_claim_submission = SupplementalClaimSubmission.find(supplemental_claim_submission_uuid)
      # TODO: perform submission, move code to here and handle results
      # cant use `perform`  
      # response = perform :post, 'supplemental_claims', request_body, headers
      # raise_schema_error_unless_200_status response.status
      # validate_against_schema json: response.body, schema: SC_CREATE_RESPONSE_SCHEMA,
      #                         append_to_error_class: ' (SC_V1)'
      response = {id: 1234}                    
      supplemental_claim_submission.saved_claim_id = response[:id]
      supplemental_claim_submission.save!
      # TODO: handle any error cases 
      # TODO: retry logic? 
      # StatsD.increment("#{STATSD_KEY_PREFIX}.success")
    rescue => e
      handle_error(e)
    end

    def handle_error(e)
      # StatsD.increment("#{STATSD_KEY_PREFIX}.error")
      raise e
    end
  end
end