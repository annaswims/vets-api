# frozen_string_literal: true
require 'sentry_logging'
require 'decision_review_v1/service'

class AppealSubmission < ApplicationRecord
  APPEAL_TYPES = %w[HLR NOD SC].freeze
  # DECISION_REVIEW_V1_SERVICE = DecisionReviewV1::Service.new

  # validates :user_uuid, presence: true
  validates :user_uuid, presence: true

  validates :type_of_appeal, inclusion: APPEAL_TYPES

  has_kms_key
  has_encrypted :form_json, :headers, :upload_metadata, key: :kms_key, **lockbox_options

  has_many :appeal_submission_uploads, dependent: :destroy

  def submit_claim
    case type_of_appeal
    when 'HLR'
    when 'NOD'
    when 'SC'
      DecisionReviewV1::Service.new.submit_supplemental_claim(request_body: self.form_json, headers: self.headers)
    else 
      raise 'Unknown Appeal Type'
    end
  end

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
