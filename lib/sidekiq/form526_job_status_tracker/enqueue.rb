
module Sidekiq
  module Form526JobStatusTracker
    module BackupSubmission
      class Enqueue
        include SentryLogging
        include Sidekiq::Worker
        sidekiq_options retry: 0

        def perform(form526_submission_id)
          return unless enabled?
          job_status = Form526JobStatus.create(job_class: 'BackupSubmission', status: 'pending', form526_submission_id: form526_submission_id, job_id: jid)
          begin
            BackupSubmission::Processor.new(form526_submission_id).process!
            job_status.update(status: Form526JobStatus::STATUS[:success])
          rescue => error
            # log error
            job_status.update(status: Form526JobStatus::STATUS[:exhausted])
          end
        end

        private

        def enabled?
          Flipper.enabled?(:form526_submit_to_central_mail_on_exhaustion)
        end
      end
    end
  end
end