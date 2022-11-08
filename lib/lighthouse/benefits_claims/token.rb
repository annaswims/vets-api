# frozen_string_literal: true

require 'common/client/base'
require 'common/client/concerns/monitoring'
require 'common/client/errors'
require 'common/exceptions/forbidden'
require 'common/exceptions/schema_validation_errors'
require 'lighthouse/benefits_claims/token_configuration'

module BenefitsClaims
  ##
  # Proxy Service for the Lighthouse Benefits Reference Data API.
  #
  class TokenService < Common::Client::Base
    include SentryLogging
    include Common::Client::Concerns::Monitoring

    configuration BenefitsClaims::TokenConfiguration

    @@access_token = nil
    @@expiry = Time.current

    def with_access_token
      get_access_token if expired?
      yield @@access_token
    end

    private

    def expired?
      Time.current.to_i >= @@expiry.to_i
    end

    ##
    # Hit a Benefits Reference Data End-point
    #
    # @path end-point [string|symbol] a string or symbol of the end-point you wish to hit.
    # @params params hash [Hash] a hash of key-value pairs of parameters
    #
    # @return [Faraday::Response]
    #
    def get_access_token
      puts "GETTING ACCESS TOKEN"
      body = config.get_access_token

      set_access_token(body['access_token'])
      set_expiry(body['expires_in'].to_i)
    end

    def set_access_token(new_access_token)
      @@access_token = new_access_token
    end

    def set_expiry(duration)
      # We want to request a new access token before
      # the existing one actually expires
      threshold = duration - 10
      new_expiry = Time.current.to_i + threshold

      @@expiry = Time.at(new_expiry).to_datetime
    end
  end
end