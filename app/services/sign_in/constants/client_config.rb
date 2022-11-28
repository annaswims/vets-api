# frozen_string_literal: true

module SignIn
  module Constants
    module ClientConfig
      CLIENT_IDS = [
        WEB_CLIENT = 'web',
        MOBILE_CLIENT = 'mobile',
        MOBILE_TEST_CLIENT = 'mobile_test'
      ].freeze
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
    end
  end
end
