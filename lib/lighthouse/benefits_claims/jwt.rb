# frozen_string_literal: true

module BenefitsClaims
  class JWTGenerator
    def settings
      Settings.lighthouse.benefits_claims
    end

    def payload
      {
        iss: settings.client_id,
        sub: settings.client_id,
        aud: settings.aud_claim_url,
        iat: 0.minutes.from_now.to_i,
        exp: 15.minutes.from_now.to_i
      }
    end

    def rsa_key
      @key ||= OpenSSL::PKey::RSA.new(File.read(settings.pem))
    end

    def token
      @token ||= JWT.encode(payload, rsa_key, 'RS256')
    end
  end
end
