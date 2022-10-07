# frozen_string_literal: true

module AppealsApi
  class OAuthApplicationController < ::OpenidApplicationController
    include AppealsApi::MPIVeteran
    before_action :verify_oauth_token!
    before_action :verify_oauth_scopes!

    # HEADERS should be a list of header names of interest, defined in the parent
    # controller based on the form schema.
    #
    # @return [Hash<String,String>] request headers of interest as a hash
    def request_headers
      return {} unless defined? self.class::HEADERS

      self.class::HEADERS.index_with { |key| request.headers[key] }.compact
    end

    #
    # Override this in individual controllers if needed to return a list of required OAuth
    # scopes based on the context.
    # FIXME: replace these with actual scopes
    #
    # @return [Array<String>] OAuth scopes required for a successful current request
    def oauth_scopes
      case action_name
      when 'index'
        %w[claim.read]
      when 'show'
        %w[claim.read]
      when 'create'
        %w[claim.write]
      else
        []
      end
    end

    #
    # Overrides the default value defined in OpenidApplicationController and is
    # required for the Client Credential Grant (CCG) flow.
    #
    # @return [String] The OAuth audience for the appeals API
    def fetch_aud
      # FIXME: replace with actual value
      Settings.oidc.isolated_audience.claims
    end

    #
    # Verify that the CCG token is valid or that the OAuth user matches the target veteran
    #
    # @return [boolean] True if the current authenticated user is the target veteran
    def verify_oauth_token!
      if token.client_credentials_token?
        validate_ccg_token!
        return
      end

      return if user_is_target_veteran? || user_represents_veteran?

      raise ::Common::Exceptions::Forbidden
    end

    #
    # Verify that the token's OAuth scope(s) match the required scopes, if any
    #
    def verify_oauth_scopes!
      token_scopes = token.payload['scp'] || []
      oauth_scopes.each do |scope|
        raise ::Common::Exceptions::Forbidden unless token_scopes.include? scope
      end
    end

    private

    def error_klass(error_detail_string)
      # Errors from the jwt gem (and other dependencies) are re-raised with
      # this class so we can exclude them from Sentry without needing to know
      # all the classes used by our dependencies.
      Common::Exceptions::TokenValidationError.new(detail: error_detail_string)
    end

    def handle_opaque_token(token_string, aud)
      opaque_token = OpaqueToken.new(token_string, aud)
      @session = Session.find(hash_token(opaque_token))
      if @session.nil?
        opaque_token.set_payload(fetch_issued(token_string))
        opaque_token.set_is_ssoi(!opaque_token.static?)
        return opaque_token if TokenUtil.validate_token(opaque_token)
      elsif @session.profile.attrs['iss'] == 'VA_SSOi_IDP'
        opaque_token.set_is_ssoi(true)
        return opaque_token
      end
      raise error_klass('Invalid token.')
    end

    def jwt?(token_string)
      JWT.decode(token_string, nil, false, algorithm: 'RS256')
      true
    rescue JWT::DecodeError
      false
    end

    def token_from_request
      authorization = request.authorization.to_s
      token_is_valid = ::OpenidApplicationController::TOKEN_REGEX.match?(authorization)
      raise error_klass('Invalid token.') unless token_is_valid

      token_string = authorization.sub(::OpenidApplicationController::TOKEN_REGEX, '').gsub(/^"|"$/, '')
      if jwt?(token_string)
        Token.new(token_string, fetch_aud)
      else
        # Handle opaque token
        # FIXME: this will be the wrong Settings value
        return handle_opaque_token(token_string, fetch_aud) if Settings.oidc.issued_url

        raise error_klass('Invalid token.')
      end
    end

    def token
      @token ||= token_from_request
    end

    #
    # Determine if the current authenticated user is the Veteran being acted on
    #
    # @return [boolean] True if the current user is the Veteran being acted on, false otherwise
    def user_is_target_veteran?
      return false if @current_user.icn.blank?

      @current_user.icn == target_veteran_icn
    end

    #
    # Determine if the current authenticated user is the target veteran's representative
    #
    # @return [boolean] True if the current authenticated user is the target veteran's representative
    def user_represents_veteran?
      return false unless @current_user

      reps = ::Veteran::Service::Representative.all_for_user(
        first_name: @current_user.first_name,
        last_name: @current_user.last_name
      )

      return false if reps.blank?
      return false if reps.count > 1

      rep = reps.first
      veteran_poa_code = ::Veteran::User.new(target_veteran)&.power_of_attorney&.code

      return false if veteran_poa_code.blank?

      rep&.poa_codes&.include?(veteran_poa_code) || false
    end

    def token_validation_client
      # FIXME: replace with actual key
      @client ||= TokenValidation::V2::Client.new(api_key: Settings.claims_api.token_validation.api_key)
    end

    def validate_ccg_token!
      root_url = request.base_url == 'https://api.va.gov' ? 'https://api.va.gov' : 'https://sandbox-api.va.gov'
      oauth_scopes.each do |scope|
        @is_valid_ccg_flow = token_validation_client.token_valid?(
          # FIXME: replace with actual URL
          audience: "#{root_url}/services/claims",
          scope: scope,
          token: token
        )
        raise ::Common::Exceptions::Forbidden unless @is_valid_ccg_flow
      end
    end
  end
end
