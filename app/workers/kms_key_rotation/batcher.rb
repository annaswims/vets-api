# frozen_string_literal: true

module KMSKeyRotation
  class Batcher
    include Sidekiq::Worker

    LIMIT = 1000

    attr_reader :batch

    def initialize
      @batch = Sidekiq::Batch.new
      batch.description = "KMS Key Rotation #{batch.bid}"
      batch.on(:success, KMSKeyRotation::Batcher::Callback, 'success')
    end

    def batch_records
      records = get_records
      return nil if records.empty?

      batch.jobs do
        records.each { |record| KMSKeyRotation::UpdateRecordJob.new.perform_async(record) }
      end
    end

    private

    def get_records
      models = get_models
      models.each_with_object([]).with_index do |(model, selected_records), index|
        selected_records << model
                            .where('encryption_updated_at = ? OR encryption_updated_at < ?', nil, 11.months.ago)
                            .limit(LIMIT - selected_records.count)
        break if selected_records.count == LIMIT || index == models.count - 1

        next
      end
    end

    def get_models
      ApplicationRecord.descendants_using_encryption.map(&:name).map(&:constantize).each do |model|
        model.descendants.empty? && model.try(:lockbox_attributes) && !model.lockbox_attributes.empty?
      end
    end

    def on_complete
      status = Sidekiq::Batch::Status.new(batch.bid)
      # log total jobs in batch - status.total
      # log total failures - status.failures
      # do we need to retry failed jobs? - status.failure_info # an array of failed jobs
      KMSKeyRotation::Batcher.new
    end
  end
end
