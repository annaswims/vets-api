# frozen_string_literal: true

require 'sentry_logging'
require 'decision_review/service'

module DecisionReview
  class SubmitAppeal
    include Sidekiq::Worker
    include SentryLogging

    SENTRY_TAG = { team: 'vfs-ebenefits' }.freeze
    STATSD_KEY_PREFIX = 'worker.decision_review.submission_attempt'
    sidekiq_options retry: 15

    ##
    # Make a request to lighthosue to submit an appeal (HLR,NOD, SUPPLEMENTAL) claim
    #
    # @param appeal [Appeal] The supplemental claim uuid
    #   We are passing in an AppealSumbission object
    # @returns [Faraday::Response]
    #
    def perform(appeal)
      # TODO: Figure out what tag to put here
      # Raven.tags_context(source: '10182-board-appeal')
      appeal_submission = AppealSubmission.find_by(appeal)
      response = appeal_submission.submit_claim
      if response.success?
        appeal_submission.update({
                                   submitted_appeal_uuid: response.body['data']['id'],
                                   submission_status: :lighthouse_received,
                                   ## flush PII containing fields once submission is successful, it is no longer needed
                                   headers: nil,
                                   form_json: nil
                                 })
        log_message_to_sentry('Successful appeal submitted', :info, sentry_success_info(appeal_submission), SENTRY_TAG)
        StatsD.increment("#{STATSD_KEY_PREFIX}.success")
        response
      else
        StatsD.increment('worker.decision_review.sc.submit.failure')
        raise 'Could not submit, non 200 return from lighthouse, Sidekiq will retry.'
      end
    rescue => e
      # have to impliment this error handing
      handle_error(e)
    end

    def handle_error(e)
      log_exception_to_sentry(e, {}, SENTRY_TAG)
      StatsD.increment("#{STATSD_KEY_PREFIX}.error")
      raise e
    end

    private

    def sentry_success_info(appeal_submission)
      {
        user_uuid: appeal_submission.user_uuid,
        type_of_appeal: appeal_submission.type_of_appeal,
        submitted_appeal_uuid: appeal_submission.submitted_appeal_uuid
      }
    end
  end
end
