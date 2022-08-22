class AddSupplementalClaimSubmissionTable < ActiveRecord::Migration[6.1]
  def up
    create_table "supplemental_claim_submissions", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string "user_uuid"
      t.string "status", default: :pending_submission
      t.string "saved_claim_id", default: nil
      t.text "form_json_ciphertext"
      t.text "headers_ciphertext"
      t.string "sidekiq_job_id"
      t.datetime "created_at", precision: 6, null: false
      t.datetime "updated_at", precision: 6, null: false
    end
  end
  def down
    drop_table :supplemental_claim_submissions
  end
end
