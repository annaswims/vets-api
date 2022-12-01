# frozen_string_literal: true

module KmsKeyRotation
  class Batcher
    LIMIT = 100
    BULK_NUMBER = LIMIT / 10

    attr_reader :batch

    def initialize
      @batch = Sidekiq::Batch.new
      @batch.description = "KMS Key Rotation #{batch.bid}"
      @batch.on(:success, KmsKeyRotation::Batcher)
      @batch.on(:complete, KmsKeyRotation::Batcher)
    end

    def batch_records
      records = get_records
      return nil if records.empty?

      batch.jobs do
        records.in_groups_of(BULK_NUMBER).each do |records_group|
          record_identifiers = records_group.each_with_object([]) do |record, identifiers|
            identifiers << [{ model: record.class.name, id: record.id }.to_json] if record.present?
          end

          byebug
          # the following is for debugging purposes only
          record_identifiers.each { |record_identifier| KmsKeyRotation::UpdateRecordsJob.perform_async(record_identifier.first) }
          
          # Sidekiq::Client.push_bulk('class' => KmsKeyRotation::UpdateRecordsJob, 'args' => record_identifiers)
        end
      end
    end

    def on_success
      puts 'success!'
    end

    def on_complete
      puts 'complete!'

      status = Sidekiq::Batch::Status.new(batch.bid)
      # log total jobs in batch - status.total
      # log total failures - status.failures
      # do we need to retry failed jobs? - status.failure_info # an array of failed jobs
      KmsKeyRotation::Batcher.new
    end

    private

    def get_records
      get_models.each_with_object([]) do |model, records|
        records << model.where('encryption_updated_at IS NULL OR encryption_updated_at < ?', 11.months.ago)
                        .limit(LIMIT - records.count)
        break if records.count == LIMIT
      end.flatten
    end

    def get_models
      tables = {}

      ApplicationRecord.descendants_using_encryption.each_with_object([]) do |model, models|
        next if tables[model.table_name]

        models << model
        tables[model.table_name] = true
      end.map(&:name).map(&:constantize)
    end
  end
end
