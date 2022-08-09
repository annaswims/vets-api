# frozen_string_literal: true

require 'decision_review_v1/service'

module DecisionReviewV1
  class Submit
    include Sidekiq::Worker
    STATSD_KEY_PREFIX = 'worker.decision_review_v1.submit'

    sidekiq_options retry: 10

    # Make a request to lighthouse to submit the claim,
    # then update our records
    #
    # @param record_id [String] The uuid of the record in our db
    def perform(record_id)
      # maybe first find the record and then determine NOD, SC or HLR:
      # Raven.tags_context(source: '10182-board-appeal')

      # find the record
      record = AppealSubmission.find(record_id)
      puts '---'
      puts record.type_of_appeal
      puts record.id

      # TODO: try submitting to Lighthouse

      # TODO: save the record when successful
    rescue => e
      handle_error(e)
    end

    def handle_error(e)
      StatsD.increment("#{STATSD_KEY_PREFIX}.error")
      raise e
    end
  end
end
