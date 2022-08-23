# frozen_string_literal: true

require 'sentry_logging'
require 'decision_review_v1/service'

class SupplementalClaimSubmission < ApplicationRecord
  include SentryLogging

  # A supplemental claim compensation form record. This class is used to persist the post transformation form
  # and track submission workflow steps.
  #
  # @!attribute id
  #   @return [Integer] uuid of submission.
  # @!attribute status
  #   @return [String] status of the submission.
  # @!attribute sidekiq_job_id
  #   @return [String] status of the submission.
  # @!attribute user_uuid
  #   @return [String] points to the user's uuid from the identity provider.
  # @!attribute saved_claim_id
  #   @return [Integer] the related saved claim id returned from lighthouse (only populated after successful submission).
  # @!attribute form_json
  #   @return [String] encrypted form submission as JSON.
  # @!attribute workflow_complete
  #   @return [Boolean] are all the steps (jobs {}) of the submission
  # @!attribute created_at
  #   @return [Timestamp] created at date.
  # @!attribute updated_at
  #   @return [Timestamp] updated at date.
  #

  # validates :user_uuid, presence: true
  # belongs_to :user_account

  has_encrypted  :form_json, :headers, **lockbox_options

  def submit!
    dr_service = DecisionReviewV1::Service.new
    dr_service.submit_supplemental_claim(request_body: self.form_json, headers: self.headers)
  end
end
