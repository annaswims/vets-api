# frozen_string_literal: true
require 'json_marshal/marshaller'

class ClaimsApi::EvidenceWaiverSubmission < ApplicationRecord
  validates :auth_headers_ciphertext, presence: true
  validates :cid, presence: true

  serialize :auth_headers, JsonMarshal::Marshaller
  serialize :form_data, JsonMarshal::Marshaller

  has_kms_key
  has_encrypted :auth_headers, :form_data, key: :kms_key, **lockbox_options
end
