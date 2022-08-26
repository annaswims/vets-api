# frozen_string_literal: true
require 'sentry_logging'
require 'decision_review_v1/service'

class AppealSubmission < ApplicationRecord
  include SentryLogging

  APPEAL_TYPES = %w[HLR NOD SC].freeze
  SENTRY_TAG = { team: 'vfs-ebenefits' }.freeze

  validates :user_uuid, presence: true

  validates :type_of_appeal, inclusion: APPEAL_TYPES

  has_kms_key
  has_encrypted :form_json, :headers, :upload_metadata, key: :kms_key, **lockbox_options

  has_many :appeal_submission_uploads, dependent: :destroy

  def wrap_in_error_handling
    begin
      # Have to deal with 2 different types of failure. Ruby errors/exceptions from submitting are caught here.
      # Non-successful http responses from submission are handled in each individual submission class.
      # For example: app/workers/decision_review/submit_appeal.rb:25
      ret = yield
      StatsD.increment("worker.decision_review.#{type_of_appeal.downcase}.submit.success")
      return ret
    rescue => e
      log_exception_to_sentry(
        e,
        {
          error_message: 'Ruby error in appeal submission sidekiq job',
          type_of_appeal: type_of_appeal
        },
        SENTRY_TAG
      )
      StatsD.increment("worker.decision_review.#{type_of_appeal.downcase}.submit.error")
      raise e
    end
  end

  # Used in apiVersion v2
  def submit_claim
    case type_of_appeal
    when 'HLR'
      wrap_in_error_handling { DecisionReviewV2::Service.new.submit_higher_level_review(request_body: self.form_json, headers: self.headers) }
    when 'NOD'
      wrap_in_error_handling { DecisionReviewV2::Service.new.submit_notice_of_disagreement(request_body: self.form_json, headers: self.headers) }
    when 'SC'
      wrap_in_error_handling { DecisionReviewV2::Service.new.submit_supplemental_claim(request_body: self.form_json, headers: self.headers) }
    else 
      emsg = "Unknown Appeal Type \"#{type_of_appeal}\""
      log_message_to_sentry(emsg, :error, {unknown_type_of_appeal: type_of_appeal}, SENTRY_TAG)
      raise emsg
    end
  end
  

  # Have to keep this here for V0 compatibility, but this is NOT sidekiq queued.
  # V1 of this submission is sidekiq queued and handled above in the `submit_claim` function.
  # See: app/controllers/v0/notice_of_disagreements_controller.rb:6
  def self.submit_nod(request_body_hash:, current_user:)
    appeal_submission = new(type_of_appeal: 'NOD',
                            user_uuid: current_user.uuid,
                            board_review_option: request_body_hash['data']['attributes']['boardReviewOption'],
                            upload_metadata: DecisionReview::Service.file_upload_metadata(current_user))

    uploads_arr = request_body_hash.delete('nodUploads')

    nod_response_body = DecisionReview::Service.new
                                               .create_notice_of_disagreement(request_body: request_body_hash,
                                                                              user: current_user)
                                               .body
    appeal_submission.submitted_appeal_uuid = nod_response_body.dig('data', 'id')
    appeal_submission.save!
    # Clear in-progress form if submit was successful
    InProgressForm.form_for_user('10182', current_user)&.destroy! unless appeal_submission.submitted_appeal_uuid.empty?

    appeal_submission.enqueue_uploads(uploads_arr, current_user)
    nod_response_body
  end

  def enqueue_uploads(uploads_arr, _user)
    uploads_arr.each do |upload_attrs|
      asu = AppealSubmissionUpload.create(decision_review_evidence_attachment_guid: upload_attrs['confirmationCode'],
                                          appeal_submission_id: id)
      DecisionReview::SubmitUpload.perform_async(asu.id)
    end
  end
end
