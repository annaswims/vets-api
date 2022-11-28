# frozen_string_literal: true

module KmsKeyRotation
  class UpdateRecordsJob
    include Sidekiq::Job

    def perform(records)
      puts 'perform key rotation!'
      records.each { |record| record.rotate_kms_key! }
    end
  end
end
