# frozen_string_literal: true

module SignIn
  class RefreshToken
    include ActiveModel::Validations

    attr_reader(
      :user_uuid,
      :uuid,
      :session_handle,
      :parent_refresh_token_hash,
      :anti_csrf_token,
      :nonce,
      :version,
      :fingerprint
    )

    validates :user_uuid, :uuid, :session_handle, :anti_csrf_token, :nonce, :version, :fingerprint, presence: true
    validates :version, inclusion: Constants::RefreshToken::VERSION_LIST

    # rubocop:disable Metrics/ParameterLists
    def initialize(session_handle:,
                   user_uuid:,
                   anti_csrf_token:,
                   uuid: create_uuid,
                   parent_refresh_token_hash: nil,
                   nonce: create_nonce,
                   version: Constants::RefreshToken::CURRENT_VERSION,
                   fingerprint: nil)
      @user_uuid = user_uuid
      @uuid = uuid
      @session_handle = session_handle
      @parent_refresh_token_hash = parent_refresh_token_hash
      @anti_csrf_token = anti_csrf_token
      @nonce = nonce
      @version = version
      @fingerprint = fingerprint

      validate!
    end
    # rubocop:enable Metrics/ParameterLists

    def persisted?
      false
    end

    private

    def create_uuid
      SecureRandom.uuid
    end

    def create_nonce
      SecureRandom.hex
    end
  end
end
