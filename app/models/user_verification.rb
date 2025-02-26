# frozen_string_literal: true

class UserVerification < ApplicationRecord
  has_one :deprecated_user_account, dependent: :destroy, required: false
  belongs_to :user_account, dependent: nil

  validate :single_credential_identifier
  validate :backing_uuid_credentials

  def verified?
    verified_at.present? && user_account.verified?
  end

  def credential_type
    return SAML::User::IDME_CSID if idme_uuid
    return SAML::User::LOGINGOV_CSID if logingov_uuid
    return SAML::User::MHV_ORIGINAL_CSID if mhv_uuid
    return SAML::User::DSLOGON_CSID if dslogon_uuid
  end

  def credential_identifier
    idme_uuid || logingov_uuid || mhv_uuid || dslogon_uuid
  end

  def backing_credential_identifier
    logingov_uuid || idme_uuid || backing_idme_uuid
  end

  private

  # XOR operators between the four credential identifiers mean one, and only one, of these can be
  # defined, If two or more are defined, or if none are defined, then a validation error is raised
  def single_credential_identifier
    unless idme_uuid.present? ^ logingov_uuid.present? ^ mhv_uuid.present? ^ dslogon_uuid.present?
      errors.add(:base, 'Must specify one, and only one, credential identifier')
    end
  end

  # All credentials require either an idme_uuid or logingov_uuid, mhv/dslogon credential types
  # store the backing idme_uuid as backing_idme_uuid
  def backing_uuid_credentials
    unless idme_uuid || logingov_uuid || backing_idme_uuid
      errors.add(:base, 'Must define either an idme_uuid, logingov_uuid, or backing_idme_uuid')
    end
  end
end
