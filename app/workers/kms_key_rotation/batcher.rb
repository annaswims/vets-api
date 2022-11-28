# frozen_string_literal: true

module KmsKeyRotation
  class Batcher
    LIMIT = 1000
    DIVIDER = 10
    BULK = LIMIT / DIVIDER

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
        0.upto((records.count / DIVIDER).ceil) do |i|
          Sidekiq::Client.push_bulk('class' => KmsKeyRotation::UpdateRecordJob, 'args' => records[from(i)..to(i)])
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

    def from(i)
      i * BULK
    end

    def to(i)
      (i + 1) * BULK - 1
    end
  end
end
