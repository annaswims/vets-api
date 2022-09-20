FactoryBot.define do
  factory :claims_api_evidence_waiver_submission, class: 'ClaimsApi::EvidenceWaiverSubmission' do
    auth_headers_ciphertext { "MyText" }
    form_data_ciphertext { "MyText" }
    encrypted_kms_key { "MyText" }
    cid { "" }
  end
end
