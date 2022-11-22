# frozen_string_literal: true

module SignIn
  module Constants
    module ClientConfig
      CLIENT_IDS = [MOBILE_CLIENT = 'mobile', MOBILE_TEST_CLIENT = 'mobile_test', WEB_CLIENT = 'web'].freeze
      CLIENTS = {
        "#{WEB_CLIENT}": {
          cookie_auth: true,
          anti_csrf: true,
          redirect_uri: Settings.sign_in.client_redirect_uris.web,
          access_token_duration: Constants::AccessToken::VALIDITY_LENGTH_SHORT_MINUTES.minutes,
          access_token_audience: 'va.gov',
          refresh_token_duration: Constants::RefreshToken::VALIDITY_LENGTH_SHORT_MINUTES.minutes
        },
        "#{MOBILE_CLIENT}": {
          cookie_auth: false,
          anti_csrf: false,
          redirect_uri: Settings.sign_in.client_redirect_uris.mobile,
          access_token_duration: Constants::AccessToken::VALIDITY_LENGTH_LONG_MINUTES.minutes,
          access_token_audience: 'vamobile',
          refresh_token_duration: Constants::RefreshToken::VALIDITY_LENGTH_LONG_DAYS.minutes
        },
        "#{MOBILE_TEST_CLIENT}": {
          cookie_auth: false,
          anti_csrf: false,
          redirect_uri: Settings.sign_in.client_redirect_uris.mobile_test,
          access_token_duration: Constants::AccessToken::VALIDITY_LENGTH_SHORT_MINUTES.minutes,
          access_token_audience: 'vamobile',
          refresh_token_duration: Constants::RefreshToken::VALIDITY_LENGTH_SHORT_MINUTES.minutes
        },
      }
      AUDIENCE = [MOBILE_AUDIENCE = 'vamobile', MOBILE_TEST_AUDIENCE = 'vamobile', WEB_AUDIENCE = 'va.gov'].freeze
      COOKIE_AUTH = [WEB_CLIENT].freeze
      API_AUTH = [MOBILE_CLIENT, MOBILE_TEST_CLIENT].freeze
      ANTI_CSRF_ENABLED = [WEB_CLIENT].freeze
      SHORT_TOKEN_EXPIRATION = [WEB_CLIENT].freeze
      LONG_TOKEN_EXPIRATION = [MOBILE_CLIENT, MOBILE_TEST_CLIENT].freeze
    end
  end
end
