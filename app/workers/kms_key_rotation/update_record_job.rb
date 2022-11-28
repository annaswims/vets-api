# frozen_string_literal: true

module KmsKeyRotation
  class UpdateRecordJob
    include Sidekiq::Job

    def perform(record)
      puts 'perform key rotation!'
      # record.rotate_kms_key!
    end
  end
end
