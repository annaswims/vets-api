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
      models = get_model_names
      records = models.each_with_object([]) do |model, selected_records|
        selected_records << m.where("encryption_updated_at = ? OR encryption_updated_at < ?", nil, 11.months.ago).limit(LIMIT - selected_records.count)
        break if selected_records.count == LIMIT
        next
      end

    
      batch.jobs do
        records.each { |records| KMSKeyRotation::UpdateRecordJob.perform_async(records) }
      end
    end

    private

    def get_model_names
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