# frozen_string_literal: true

require 'common/client/configuration/rest'
require 'lighthouse/benefits_claims/token'

module BenefitsClaims
  ##
  # HTTP client configuration for the {BenefitsClaims::Service},
  # sets the base path, the base request headers, and a service name for breakers and metrics.
  #
  class Configuration < Common::Client::Configuration::REST
    self.read_timeout = Settings.lighthouse.benefits_claims.timeout || 20

    ##
    # @return [Config::Options] Settings for benefits_claims API.
    #
    def settings
      Settings.lighthouse.benefits_claims
    end

    ##
    # @return [String] Base path for benefits_claims URLs.
    #
    def base_path
      "#{settings.host}/#{settings.path}"
    end

    ##
    # @return [String] Service name to use in breakers and metrics.
    #
    def service_name
      'BenefitsClaims'
    end

    ##
    # @return [Faraday::Response] 
    #
    def get(path, params = {})
      token_service.with_access_token do |access_token|
        connection.get(path, params, { Authorization: "Bearer #{access_token}"})
      end
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

        faraday.request(:curl, ::Logger.new(STDOUT), :warn) unless Rails.env.production?
        faraday.request :multipart
        faraday.request :json

        faraday.response :betamocks if mock_enabled?
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
    end

    ##
    # @return [Boolean] Should the service use mock data in lower environments.
    #
    def mock_enabled?
      settings.mock || false
    end

    ##
    # @return [BenefitsClaims::TokenService] Service used to generate access tokens.
    #
    def token_service
      puts TokenService.new.class
      @token_service ||= TokenService.new()
    end
  end
end
