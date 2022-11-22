# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

class AddColumnEncryptionUpdatedAtToTablesThatNeedToBeEncrypted < ActiveRecord::Migration[6.1]
  def change
    add_column :form_attachments, :encryption_updated_at, :datetime
    add_column :appeal_submissions, :encryption_updated_at, :datetime
    add_column :saved_claims, :encryption_updated_at, :datetime
    add_column :education_stem_automated_decisions, :encryption_updated_at, :datetime
    add_column :form1095_bs, :encryption_updated_at, :datetime
    add_column :form526_submissions, :encryption_updated_at, :datetime
    add_column :form5655_submissions, :encryption_updated_at, :datetime
    add_column :gibs_not_found_users, :encryption_updated_at, :datetime
    add_column :in_progress_forms, :encryption_updated_at, :datetime
    add_column :persistent_attachments, :encryption_updated_at, :datetime
    add_column :async_transactions, :encryption_updated_at, :datetime
    add_column :veteran_representatives, :encryption_updated_at, :datetime
    add_column :health_quest_questionnaire_responses, :encryption_updated_at, :datetime
    add_column :covid_vaccine_expanded_registration_submissions, :encryption_updated_at, :datetime
    add_column :covid_vaccine_registration_submissions, :encryption_updated_at, :datetime
    add_column :claims_api_auto_established_claims, :encryption_updated_at, :datetime
    add_column :claims_api_evidence_waiver_submissions, :encryption_updated_at, :datetime
    add_column :claims_api_power_of_attorneys, :encryption_updated_at, :datetime
    add_column :claims_api_supporting_documents, :encryption_updated_at, :datetime
    add_column :appeals_api_higher_level_reviews, :encryption_updated_at, :datetime
    add_column :appeals_api_notice_of_disagreements, :encryption_updated_at, :datetime
    add_column :appeals_api_supplemental_claims, :encryption_updated_at, :datetime
  end
end
# rubocop:enable Metrics/MethodLength
