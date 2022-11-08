# frozen_string_literal: true

require 'common/client/configuration/rest'
require 'lighthouse/benefits_claims/jwt'

module BenefitsClaims
  ##
  # HTTP client configuration for the {BenefitsClaims::Service},
  # sets the base path, the base request headers, and a service name for breakers and metrics.
  #
  class TokenConfiguration < Common::Client::Configuration::REST
    ##
    # @return [Config::Options] Settings for benefits_claims API
    #
    def settings
      Settings.lighthouse.benefits_claims
    end

    self.read_timeout = Settings.lighthouse.benefits_claims.timeout || 20

    ##
    # @return [String] Base path for benefits_claims URLs.
    #
    def base_path
      settings.host
    end

    ##
    # @return [Hash] The basic headers required for any benefits_claims API call.
    #
    def self.base_request_headers
      super.merge({ 'Content-Type': 'application/x-www-form-urlencoded' })
    end

    def get_access_token
      connection.post('/oauth2/claims/system/v1/token', URI.encode_www_form(body)).body
    end

    ##
    # Creates a Faraday connection with parsing json and adding breakers functionality.
    #
    # @return [Faraday::Connection] a Faraday connection instance.
    #
    def connection
      @conn ||= Faraday.new(base_path, headers: base_request_headers, request: request_options) do |faraday|
        faraday.use      :breakers
        faraday.use      Faraday::Response::RaiseError

        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
    end

    private

    ##
    # @return [String] new JTW token
    #
    def token
      jwt_generator.generate_token
    end

    def body
      {
        grant_type: 'client_credentials',
        client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
        client_assertion: token,
        scope: settings.api_scope.join(' ')
      }.as_json
    end

    def jwt_generator
      @generator ||= JWTGenerator.new
    end
  end
end
