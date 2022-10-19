# frozen_string_literal: true

module KmsKeyRotation
  class UpdateRecordJob
    include Sidekiq::Worker

    def perform(record:)
      record.rotate_kms_key!
    end
  end
end
