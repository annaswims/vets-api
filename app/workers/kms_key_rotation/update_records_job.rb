# frozen_string_literal: true

module KmsKeyRotation
  class UpdateRecordsJob
    include Sidekiq::Job

    def perform(json)
      record_identifiers = JSON.parse(json)
      record_identifiers['model'].constantize.find(record_identifiers['id']).rotate_kms_key!
      # This calls config/initializers/kms_encrypted_monkeypatch.rb
      # define_method("rotate_#{key_method}!") do
    end
  end
end
