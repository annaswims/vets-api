# frozen_string_literal: true

# rubocop:disable Layout/LineLength
module Swagger
  module Schemas
    class SignIn
      include Swagger::Blocks

      swagger_schema :CSPAuthFormResponse do
        property :data, type: :string
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

      swagger_schema :TokenResponse do
        key :type, :object
        property(:data) do
          key :type, :object
          property :access_token do
            key :description, 'Access token, used to obtain user attributes - 5 minute expiration'
            key :type, :string
            key :example,
                'eyJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJ2YS5nb3Ygc2lnbiBpbiIsImF1ZCI6InZhbW9iaWxlIiwiY2xpZW50X2lkIjoidmFtb2JpbGUiLCJqdGkiOiJkYTllMzY5Ny0zNmYzLTRlZGMtODZmZC03YzQyNDJhMzFmZTIiLCJzdWIiOiJkOTM3NjIyMi1jMjk0LTQwZGEtODI5MC05NmNmNjExYWRmY2MiLCJleHAiOjE2NTI3MjE3OTYsImlhdCI6MTY1MjcyMTQ5Niwic2Vzc2lvbl9oYW5kbGUiOiJlNmM4NTc5ZC04MDQxLTQ4MzYtOWJmYS1mOTAwNzk2NDMzNjYiLCJyZWZyZXNoX3Rva2VuX2hhc2giOiI4YTE4ZTJjNDRjNzRiNTBlYThlY2YzZmQ4MmFjNmYwMGE5ZjNhOTJjOTI0ZjAzYzM4ZDVhOWU5YWJiOWZlMzdiIiwicGFyZW50X3JlZnJlc2hfdG9rZW5faGFzaCI6ImVlZjcxZDY1OWE5NDQ5YTA4ODE1MWM1NmFkMzgwZTA5ZThmYTQ2YTc2ODhmYWY0MmUwODNlY2UzYjUwYjVjZDgiLCJhbnRpX2NzcmZfdG9rZW4iOiI3YzhmMzYyZjQ1ODk0MzMzMTRkNmRjOGU2Mzc4ODAwZCIsImxhc3RfcmVnZW5lcmF0aW9uX3RpbWUiOjE2NTI3MjE0OTYsInZlcnNpb24iOiJWMCJ9.TMQ02cRwu6hUGI07r_wjsTbz7Z6FBQPyrSOn2tZaUL401Yd6SqzRhe4FM_LBSG6Qju7bEdbH-J5PcnWsNoLnptr27c62jxl2LOw_p-jOPJrqHK8wrTODhH6Pu58KTmklnGovBUniiyRYipu1eTehuoOc6zaZKq4IYsQOEWWWNTG_jL5_CxD2W7_bLmffxQ49UbwNfkQg3lAZcRBEbB8DYEf8ay3HEEWoeGY5LLLyUnzT9vuEtdJVttvGItQWTTC1k4_ZqNqKzpRabx3utSlv65ZAYZQqDYSV50KsI6CQj9iuBfWtz-JvhzrXvBa3CwJdPFWueaEZNZr5OyB1zFg5NQ'
          end

          property :refresh_token do
            key :description, 'Refresh token, used to refresh a session and obtain new tokens - 30 minute expiration'
            key :type, :string
            key :example,
                'v1:insecure+data+A6ZXlKMWMyVnlYM1YxYVdRaU9pSmtPVE0zTmpJeU1pMWpNamswTFRRd1pHRXRPREk1TUMwNU5tTm1OakV4WVdSbVkyTWlMQ0p6WlhOemFXOXVYMmhoYm1Sc1pTSTZJbVUyWXpnMU56bGtMVGd3TkRFdE5EZ3pOaTA1WW1aaExXWTVNREEzT1RZME16TTJOaUlzSW5CaGNtVnVkRjl5WldaeVpYTm9YM1J2YTJWdVgyaGhjMmdpT2lKbFpXWTNNV1EyTlRsaE9UUTBPV0V3T0RneE5URmpOVFpoWkRNNE1HVXdPV1U0Wm1FME5tRTNOamc0Wm1GbU5ESmxNRGd6WldObE0ySTFNR0kxWTJRNElpd2lZVzUwYVY5amMzSm1YM1J2YTJWdUlqb2lOMk00WmpNMk1tWTBOVGc1TkRNek16RTBaRFprWXpobE5qTTNPRGd3TUdRaUxDSnViMjVqWlNJNklqazNObUU0WVdOaE9UZG1NRFl5TjJVM1ltUm1ZamRpTW1NMFpUbGhOMlZpSWl3aWRtVnljMmx2YmlJNklsWXdJaXdpZG1Gc2FXUmhkR2x2Ymw5amIyNTBaWGgwSWpwdWRXeHNMQ0psY25KdmNuTWlPbnQ5ZlE9PQ==.976a8aca97f0627e7bdfb7b2c4e9a7eb.V0'
          end

          property :anti_csrf_token do
            key :description,
                'Anti CSRF token, used to match `refresh` calls with the `token` call that generated the refresh token used - currently disabled, this can be ignored'
            key :type, :string
            key :example, '7c8f362f4589433314d6dc8e6378800d'
          end
        end
      end

      swagger_schema :UserAttributesResponse do
        key :type, :object
        property(:data) do
          key :type, :object
          property :id, type: :string, example: ''
          property :type, type: :string, example: 'users'
          property(:attributes) do
            key :type, :object
            property :uuid, type: :string, example: 'd9376222-c294-40da-8290-96cf611adfcc'
            property :first_name, type: :string, example: 'ALFREDO'
            property :middle_name, type: %i[null string], example: 'MATTHEW'
            property :last_name, type: :string, example: 'ARMSTRONG'
            property :birth_date, type: :string, example: '1989-11-11'
            property :email, type: :string, example: 'vets.gov.user+4@gmail.com'
            property :gender, type: :string, example: 'M'
            property :ssn, type: :string, example: '111111111'
            property :birls_id, type: %i[null string], example: '796121200'
            property :authn_context, type: :string, example: 'logingov'
            property :icn, type: :string, example: '1012846043V576341'
            property :edipi, type: %i[null string], example: '001001999'
            property :active_mhv_ids, type: :array, example: %w[12345 67890]
            property :sec_id, type: %i[null string], example: '1013173963'
            property :vet360_id, type: %i[null string], example: '18277'
            property :participant_id, type: %i[null string], example: '13014883'
            property :cerner_id, type: %i[null string], example: '9923454432'
            property :cerner_facility_ids, type: :array, example: %w[200MHV]
            property :vha_facility_ids, type: :array, example: %w[200ESR 648]
            property :id_theft_flag, type: %i[null boolean], example: false
            property :verified, type: :boolean, example: true
            property :access_token_ttl, type: :integer, example: 300
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
