# frozen_string_literal: true

desc 'rotate kms key annually'
task rotate_kms_key: :environment do
  KmsKeyRotation::Batcher.new.batch_records
end
