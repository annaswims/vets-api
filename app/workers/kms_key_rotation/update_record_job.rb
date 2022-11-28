# frozen_string_literal: true

module KmsKeyRotation
  class UpdateRecordJob
    include Sidekiq::Job

    def perform(records)
      puts 'perform key rotation!'
      records.each { |record| record.rotate_kms_key! }
    end
  end
end
