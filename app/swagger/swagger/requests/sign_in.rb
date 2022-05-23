# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Layout/LineLength
module Swagger
  module Requests
    class SignIn
      include Swagger::Blocks

      swagger_path '/sign_in/{type}/authorize' do
        operation :get do
          # extend Swagger::Responses::AuthenticationError

          key :description, 'Initializes Sign in Service authorization'
          key :operationId, 'signInAuthorize'
          key :tags, %w[
            authentication
          ]

          key :produces, ['text/html']
          key :consumes, ['application/json']

          parameter do
            key :name, 'type'
            key :in, :path
            key :description, 'Credential provider selected to authenticate with'
            key :required, true
            key :type, :string
            key :example, 'logingov'
          end

          parameter do
            key :name, 'code_challenge'
            key :in, :query
            key :description, 'Value created from a code_verifier hex that is hash and encoded'
            key :required, true
            key :type, :string
            key :example, '1BUpxy37SoIPmKw96wbd6MDcvayOYm3ptT-zbe6L_zM='
          end

          parameter do
            key :name, 'code_challenge_method'
            key :in, :query
            key :description, 'Method used to create code_challenge (*must* equal \'S256\')'
            key :required, true
            key :type, :string
            key :example, 'S256'
          end

          response 200 do
            key :description, 'Response is OK, user is redirected to credential service provider'
            schema do
              key :type, :string
              key :example, "<form id=\"oauth-form\" action=\"https://idp.int.identitysandbox.gov/openid_connect/authorize\" accept-charset=\"UTF-8\" method=\"get\">\n" \
                            "<input type=\"hidden\" name=\"acr_values\" id=\"acr_values\" value=\"http://idmanagement.gov/ns/assurance/ial/2\" autocomplete=\"off\" />\n" \
                            "<input type=\"hidden\" name=\"client_id\" id=\"client_id\" value=\"urn:gov:gsa:openidconnect.profiles:sp:sso:va:dev_signin\" autocomplete=\"off\" />\n" \
                            "<input type=\"hidden\" name=\"nonce\" id=\"nonce\" value=\"11eb8f30f120e16ccdab1327bcf031f6\" autocomplete=\"off\" />\n" \
                            "<input type=\"hidden\" name=\"prompt\" id=\"prompt\" value=\"select_account\" autocomplete=\"off\" />\n" \
                            "<input type=\"hidden\" name=\"redirect_uri\" id=\"redirect_uri\" value=\"http://localhost:3000/sign_in/logingov/callback\" autocomplete=\"off\" />\n" \
                            "<input type=\"hidden\" name=\"response_type\" id=\"response_type\" value=\"code\" autocomplete=\"off\" />\n" \
                            "<input type=\"hidden\" name=\"scope\" id=\"scope\" value=\"profile email openid social_security_number\" autocomplete=\"off\" />\n" \
                            "<input type=\"hidden\" name=\"state\" id=\"state\" value=\"d940a929b7af6daa595707d0c99bec57\" autocomplete=\"off\" />\n" \
                            "<noscript>\n" \
                            "<div> <input type=\”submit\” value=\”Continue\”/> </div>\n" \
                            "</noscript>\n" \
                            "</form>\n" \
                            "<script nonce=\"**CSP_NONCE**\">\n" \
                            "(function() {\n" \
                            "document.getElementById(\"oauth-form\").submit();\n" \
                            "})();\n" \
                            "</script>\n"
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Layout/LineLength
