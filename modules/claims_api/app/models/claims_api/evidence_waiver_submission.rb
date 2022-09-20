class ClaimsApi::EvidenceWaiverSubmission < ApplicationRecord
    serialize :auth_headers, JsonMarshal::Marshaller
    serialize :form_data, JsonMarshal::Marshaller

    has_kms_key
    has_encrypted :auth_headers, :form_data, key: :kms_key, **lockbox_options
end
