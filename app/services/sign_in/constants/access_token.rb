# frozen_string_literal: true

module SignIn
  module Constants
    module AccessToken
      VALIDITY_LENGTH_SHORT_MINUTES = 5
      VALIDITY_LENGTH_LONG_MINUTES = 30
      JWT_ENCODE_ALGORITHM = 'RS256'

      VERSION_LIST = [
        CURRENT_VERSION = 'V0'
      ].freeze

      ISSUER = 'va.gov sign in'
    end
  end
end
