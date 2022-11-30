# frozen_string_literal: true

module KmsKeyRotation
  class UpdateRecordsJob
    include Sidekiq::Job

    def perform(json)
      record = JSON.parse(json)
      record['model'].constantize.find(record['id']).rotate_kms_key!
    end
  end
end
