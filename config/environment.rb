# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

ActiveRecord::SchemaDumper.ignore_tables = ['spatial_ref_sys']

# Monkeypatch for KMS Encrypted
KmsEncrypted::Model.include KmsEncrypted::Model::Monkeypatch
