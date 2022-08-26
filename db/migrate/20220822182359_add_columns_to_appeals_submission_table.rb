class AddColumnsToAppealsSubmissionTable < ActiveRecord::Migration[6.1]
  def change
    add_column :appeal_submissions, :form_json_ciphertext, :text
    add_column :appeal_submissions, :headers_ciphertext, :text
    add_column :appeal_submissions, :sidekiq_job_id, :string
    add_column :appeal_submissions, :submission_status, :string
  end
end