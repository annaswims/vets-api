class EvidenceWaiverSubmissions < ActiveRecord::Migration[6.1]
  def change
    create_table :claims_api_evidence_waiver_submissions do |t|
      t.text :auth_headers_ciphertext
      t.text :form_data_ciphertext
      t.text :encrypted_kms_key
      t.string :cid
      t.uuid :evidence_waiver_id, null: false
      t.index ['evidence_waiver_id'], name: 'evidence_waiver_id_index'

      t.timestamps
    end
  end
end