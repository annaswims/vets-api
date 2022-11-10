# frozen_string_literal: true

require 'common/client/base'
require 'common/client/concerns/monitoring'
require 'lighthouse/benefits_claims/token_configuration'

module BenefitsClaims
  ##
  # Proxy Service for the Lighthouse Benefits Reference Data API.
  #
  class TokenService < Common::Client::Base
    configuration BenefitsClaims::TokenConfiguration
    
    EXPIRATION_LATENCY = 10

    def initialize
      super
      @access_token = nil
      @expiration = Time.current.to_i
    end

    def with_access_token
      get_access_token if expired?
      yield @access_token
    end

    private

    ##
    # Determine if the access_token is expired
    #
    # @return [Boolean]
    #
    def expired?
      Time.current.to_i >= @expiration
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
      @access_token = config.get_access_token

      decoded = JWT.decode(@access_token, nil, false, algorithm: 'RS256')
      @expiration = decoded[0]['exp'] - EXPIRATION_LATENCY
    end
  end
end
