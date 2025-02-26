# frozen_string_literal: true

require 'mail_automation/client'
require 'lighthouse/veterans_health/client'

# rubocop:disable Metrics/ModuleLength
module Form526RapidReadyForDecisionConcern
  extend ActiveSupport::Concern

  def send_rrd_alert_email(subject, message, error = nil, to = Settings.rrd.alerts.recipients)
    RrdAlertMailer.build(self, subject, message, error, to).deliver_now
  end

  def read_metadata(key)
    form.dig('rrd_metadata', key.to_s)
  end

  # @param metadata_hash [Hash] to be merged into form_json['rrd_metadata']
  def save_metadata(metadata_hash)
    form['rrd_metadata'] ||= {}
    form['rrd_metadata'].deep_merge!(metadata_hash)

    update!(form_json: JSON.dump(form))
    invalidate_form_hash
    self
  end

  def rrd_status
    return 'processed' if rrd_claim_processed?

    offramp_reason = read_metadata(:offramp_reason)
    return offramp_reason if offramp_reason.present?

    return 'error' if read_metadata(:error).present?

    'unknown'
  end

  # Fetch all claims from EVSS
  # @return [Boolean] whether there are any open EP 020's
  def pending_eps?
    pending = open_claims.any? { |claim| claim['base_end_product_code'] == '020' }
    save_metadata(offramp_reason: 'pending_ep') if pending
    pending
  end

  def rrd_pdf_created?
    read_metadata(:pdf_created) || false
  end

  def rrd_pdf_uploaded_to_s3?
    read_metadata(:pdf_guid).present?
  end

  Uploader = RapidReadyForDecision::FastTrackPdfUploadManager
  PDF_FILENAME_REGEX = /#{Uploader::DOCUMENT_NAME_PREFIX}.*#{Uploader::DOCUMENT_NAME_SUFFIX}/.freeze

  # @return if an RRD pdf has been included as a file to upload
  def rrd_pdf_added_for_uploading?
    form['form526_uploads']&.any? do |upload|
      upload['name']&.match? PDF_FILENAME_REGEX
    end
  end

  def rrd_special_issue_set?
    disabilities = form.dig('form526', 'form526', 'disabilities')
    disabilities.any? do |disability|
      disability['specialIssues']&.include?(RapidReadyForDecision::RrdSpecialIssueManager::RRD_CODE)
    end
  end

  def disabilities
    form.dig('form526', 'form526', 'disabilities')
  end

  def diagnostic_codes
    disabilities.map { |disability| disability['diagnosticCode'] }
  end

  def prepare_for_evss!
    return if pending_eps? || disabilities_not_service_connected?

    save_metadata(forward_to_mas_all_claims: true) if Flipper.enabled?(:rrd_mas_all_claims_tracking) &&
                                                      !single_issue_hypertension_cfi?

    if Flipper.enabled?(:rrd_mas_disability_tracking) && single_disability_eligible_for_mas?
      save_metadata(forward_to_mas: true)
      insert_classification_codes unless Flipper.enabled?(:rrd_mas_all_claims_notification)
    end
  end

  def send_post_evss_notifications!
    send_completed_notification if rrd_job_selector.rrd_applicable?
    conditionally_notify_mas
    send_pact_related_notification if new_pact_related_disability?
  end

  def single_issue?
    disabilities.size == 1
  end

  def single_issue_hypertension_cfi?
    single_issue? &&
      increase_only? &&
      RapidReadyForDecision::Constants.extract_disability_symbol_list(self).first == :hypertension
  end

  def increase_only?
    disabilities.all? { |disability| disability['disabilityActionType']&.upcase == 'INCREASE' }
  end

  # Return whether this Form 526 has a single disability that is eligible to be forwarded to MAS
  def single_disability_eligible_for_mas?
    return false unless single_issue?

    return true if Flipper.enabled?(:rrd_hypertension_mas_notification) && single_issue_hypertension_cfi?

    RapidReadyForDecision::Constants::MAS_DISABILITIES.include?(diagnostic_codes.first) && increase_only?
  end

  # return whether all disabilities on this form are rated as not service-connected
  def disabilities_not_service_connected?
    disabilities.pluck('ratedDisabilityId').all? do |rated_id|
      rated_id.present? && (all_rated_disabilities
                              .find { |rated| rated_id == rated.rated_disability_id }
                              &.decision_code == 'NOTSVCCON')
    end
  end

  def insert_classification_codes
    submission_data = JSON.parse(form_json)
    disabilities = submission_data.dig('form526', 'form526', 'disabilities')
    disabilities.each do |disability|
      mas_classification_code = RapidReadyForDecision::Constants::MAS_RELATED_CONTENTIONS[disability['diagnosticCode']]

      unless mas_classification_code.nil? || disability['classificationCode']
        disability['classificationCode'] = mas_classification_code
      end
    end
    update!(form_json: JSON.dump(submission_data))
    invalidate_form_hash
  end

  private

  def open_claims
    all_claims = EVSS::ClaimsService.new(auth_headers).all_claims.body
    all_claims['open_claims']
  end

  # fetch, memoize, and return all of the veteran's rated disabilities from EVSS
  def all_rated_disabilities
    @all_rated_disabilities ||= begin
      response = EVSS::DisabilityCompensationForm::Service.new(auth_headers).get_rated_disabilities
      response.rated_disabilities
    end
  end

  # @return if this claim submission was processed and fast-tracked by RRD
  def rrd_claim_processed?
    rrd_pdf_added_for_uploading? && rrd_special_issue_set?
  end

  def new_pact_related_disability?
    return false unless Flipper.enabled?(:rrd_new_pact_related_disability)

    disabilities.any? do |disability|
      disability['disabilityActionType']&.upcase == 'NEW' &&
        (RapidReadyForDecision::Constants::PACT_CLASSIFICATION_CODES.include? disability['classificationCode'])
    end
  end

  def notify_mas_tracking
    RrdMasNotificationMailer.build(self).deliver_now
  end

  def notify_mas_all_claims_tracking
    RrdMasNotificationMailer.build(self, Settings.rrd.mas_all_claims_tracking.recipients).deliver_now
  end

  def conditionally_notify_mas
    notify_mas_all_claims_tracking if read_metadata(:forward_to_mas_all_claims)
    notify_mas_tracking if read_metadata(:forward_to_mas)

    return unless Flipper.enabled?(:rrd_mas_notification)

    if read_metadata(:forward_to_mas) ||
       (Flipper.enabled?(:rrd_mas_all_claims_notification) && read_metadata(:forward_to_mas_all_claims))
      client = MailAutomation::Client.new({
                                            file_number: birls_id,
                                            claim_id: submitted_claim_id,
                                            form526: form
                                          })
      response = client.initiate_apcas_processing
      save_metadata(mas_packetId: response.dig('body', 'packetId'))
    end
  rescue => e
    send_rrd_alert_email("Failure: MA claim - #{submitted_claim_id}", e.to_s, nil,
                         Settings.rrd.mas_tracking.recipients)
  end

  def send_completed_notification
    RrdCompletedMailer.build(self).deliver_now
  end

  def send_pact_related_notification
    icn = RapidReadyForDecision::ClaimContext.new(self).user_icn
    client = Lighthouse::VeteransHealth::Client.new(icn)
    bp_readings = RapidReadyForDecision::LighthouseObservationData.new(client.list_bp_observations).transform
    meds = RapidReadyForDecision::LighthouseMedicationRequestData.new(client.list_medication_requests).transform

    RrdNewDisabilityClaimMailer.build(self, {
                                        bp_readings_count: bp_readings.length,
                                        medications_count: meds.length
                                      }).deliver_now
  end
end
# rubocop:enable Metrics/ModuleLength
