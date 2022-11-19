# frozen_string_literal: true

module BenefitsClaims
  class JWTGenerator
    TTL = 300

    def iat
      Time.now.to_i
    end

    def settings
      Settings.lighthouse.benefits_claims
    end

    def payload
      {
        iss: settings.client_id,
        sub: settings.client_id,
        aud: settings.aud_claim_url,
        iat: iat,
        exp: iat + TTL
      }
    end

    def rsa_key
      @key ||= OpenSSL::PKey::RSA.new(File.read(settings.pem))
    end

    def generate_token
      JWT.encode(payload, rsa_key, 'RS256')
    end
  end
end
