# frozen_string_literal: true

module KmsKeyRotation
  class UpdateRecordsJob
    include Sidekiq::Job

    def perform(record)
      puts "record class: #{record.class}"
      r.rotate_kms_key!
    end
  end
end
