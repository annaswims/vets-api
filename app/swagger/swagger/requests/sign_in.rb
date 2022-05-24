# frozen_string_literal: true

# rubocop:disable Layout/LineLength
module Swagger
  module Requests
    class SignIn
      include Swagger::Blocks

      swagger_path '/sign_in/{type}/authorize' do
        operation :get do
          key :description, 'Initializes Sign in Service authorization'
          key :operationId, 'getSignInAuthorize'
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
            key :name, 'state'
            key :in, :query
            key :description, 'Client-provided code that is returned to the client upon successful authentication. Minimum length is 22 characters.'
            key :required, false
            key :type, :string
            key :example, 'd940a929b7af6daa595707d0c99bec57'
          end

          parameter do
            key :name, 'code_challenge'
            key :in, :query
            key :description, 'Value created from a `code_verifier`` hex that is hash and encoded'
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
            key :description, 'User is redirected to credential service provider'
            schema { key :$ref, :CSPAuthFormResponse }
          end
        end
      end

      swagger_path '/sign_in/{type}/callback' do
        operation :get do
          key :description, 'Sign in Service authentication callback'
          key :operationId, 'getSignInCallback'
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
            key :name, 'code'
            key :in, :query
            key :description, 'Credential provider-generated authentication code used to obtain access token and user attributes'
            key :required, true
            key :type, :string
            key :example, '6966c7f6-bead-4c3e-8db9-49a5e6f50b28'
          end

          parameter do
            key :name, 'state'
            key :in, :query
            key :description, 'Client-provided code that is returned to the client upon successful authentication.'
            key :required, false
            key :type, :string
            key :example, 'd940a929b7af6daa595707d0c99bec57'
          end

          response 302 do
            key :description, 'User is created in vets-api, then redirected back to client with an authentication code that can be used to obtain tokens'
            schema do
              key :type, :string
              key :format, :uri
              key :example, 'vamobile://login-success?code=0c2d21d3-465b-4054-8030-1d042da4f667&state=d940a929b7af6daa595707d0c99bec57'
            end
          end
        end
      end

      swagger_path '/sign_in/token' do
        operation :post do
          key :description, 'Sign in Service session creation & tokens request'
          key :operationId, 'postSignInToken'
          key :tags, %w[
            authentication
          ]

          key :produces, ['application/json']
          key :consumes, ['application/json']

          parameter do
            key :name, 'grant_type'
            key :in, :path
            key :description, 'Authentication grant type value, must equal `authorization_code`'
            key :required, true
            key :type, :string
            key :example, 'authorization_code'
          end

          parameter do
            key :name, 'code_verifier'
            key :in, :query
            key :description, 'Original hex that was hashed and SHA256-encoded to create the `code_challenge` used in the `authenticate` request'
            key :required, true
            key :type, :string
            key :example, 'f2413353d83449c501b17e411d09ebb4'
          end

          parameter do
            key :name, 'code'
            key :in, :query
            key :description, 'Authentication code passed to the client through the `code` param in authentication `callback` redirect'
            key :required, true
            key :type, :string
            key :example, '0c2d21d3-465b-4054-8030-1d042da4f667'
          end

          response 200 do
            key :description, 'Authentication code and code_verifier validated, session and tokens created & tokens returned to client'
            schema { key :$ref, :TokenResponse }
          end
        end
      end

      swagger_path '/sign_in/refresh' do
        operation :post do
          key :description, 'Sign in Service session & tokens refresh'
          key :operationId, 'postSignInRefresh'
          key :tags, %w[
            authentication
          ]

          key :produces, ['application/json']
          key :consumes, ['application/json']

          parameter do
            key :name, 'refresh_token'
            key :in, :path
            key :description, 'Refresh token string, must be URI-encoded'
            key :required, true
            key :type, :string
            key :example, 'v1%3Ainsecure%2Bdata%2BA6ZXlKMWMyVnlYM1YxYVdRaU9pSmtaamt4WWpWa01pMHlaRE14TFRSbE1tSXRZbU16TXkweE1tRTRPRE5sT0ROa05tUWlMQ0p6WlhOemFXOXVYMmhoYm1Sc1pTSTZJalF5TmpZNU5UTmxMVFJrTUdRdE5EVmtZaTA1TWpOaUxUSTJaV1E0WVdJeVpXUXpPQ0lzSW5CaGNtVnVkRjl5WldaeVpYTm9YM1J2YTJWdVgyaGhjMmdpT2lKbFltSTFZVFF3TXpsaU9URmhabU01WlRnM05UVXhNVFF3WlRJM00yTTNOMkkxWkRNMU1EZzJNREpqTURBNE5HRmtaRFl4TlRBNU0yWm1OalE0WXprMUlpd2lZVzUwYVY5amMzSm1YM1J2YTJWdUlqb2lPVFJrWW1JMFkyTm1ZekJpWlRkbFptSTROVGcxWldReFpqVmhPV1UzWVRJaUxDSnViMjVqWlNJNkltWmtZVFZrWlRjMVlqZzJZakJqT1RSbVpXWXpOamcwWkRnNE5EVXhZV0kzSWl3aWRtVnljMmx2YmlJNklsWXdJaXdpZG1Gc2FXUmhkR2x2Ymw5amIyNTBaWGgwSWpwdWRXeHNMQ0psY25KdmNuTWlPbnQ5ZlE9PQ%3D%3D%2Efda5de75b86b0c94fef3684d88451ab7%2EV0'
          end

          parameter do
            key :name, 'anti_csrf_token'
            key :in, :path
            key :description, 'Anti CSRF token, used to match `refresh` calls with the `token` call that generated the refresh token used - currently disabled, this can be ignored'
            key :required, false
            key :type, :string
            key :example, '94dbb4ccfc0be7efb8585ed1f5a9e7a2'
          end

          response 200 do
            key :description, 'Refresh_token validated, session updated, new tokens created and returned to client'
            schema { key :$ref, :TokenResponse }
          end
        end
      end

      swagger_path '/sign_in/introspect' do
        operation :get do
          key :description, 'Sign in Service user introspection'
          key :operationId, 'getSignInIntrospect'
          key :tags, %w[
            authentication
          ]

          key :produces, ['application/json']
          key :consumes, ['application/json']

          parameter do
            key :name, 'access_token'
            key :in, :header
            key :description, 'Access token string, passed through Bearer authentication: `Authorization: Bearer <access_token>`'
            key :required, true
            key :type, :string
            key :example, 'eyJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJ2YS5nb3Ygc2lnbiBpbiIsImF1ZCI6InZhbW9iaWxlIiwiY2xpZW50X2lkIjoidmFtb2JpbGUiLCJqdGkiOiJkYTllMzY5Ny0zNmYzLTRlZGMtODZmZC03YzQyNDJhMzFmZTIiLCJzdWIiOiJkOTM3NjIyMi1jMjk0LTQwZGEtODI5MC05NmNmNjExYWRmY2MiLCJleHAiOjE2NTI3MjE3OTYsImlhdCI6MTY1MjcyMTQ5Niwic2Vzc2lvbl9oYW5kbGUiOiJlNmM4NTc5ZC04MDQxLTQ4MzYtOWJmYS1mOTAwNzk2NDMzNjYiLCJyZWZyZXNoX3Rva2VuX2hhc2giOiI4YTE4ZTJjNDRjNzRiNTBlYThlY2YzZmQ4MmFjNmYwMGE5ZjNhOTJjOTI0ZjAzYzM4ZDVhOWU5YWJiOWZlMzdiIiwicGFyZW50X3JlZnJlc2hfdG9rZW5faGFzaCI6ImVlZjcxZDY1OWE5NDQ5YTA4ODE1MWM1NmFkMzgwZTA5ZThmYTQ2YTc2ODhmYWY0MmUwODNlY2UzYjUwYjVjZDgiLCJhbnRpX2NzcmZfdG9rZW4iOiI3YzhmMzYyZjQ1ODk0MzMzMTRkNmRjOGU2Mzc4ODAwZCIsImxhc3RfcmVnZW5lcmF0aW9uX3RpbWUiOjE2NTI3MjE0OTYsInZlcnNpb24iOiJWMCJ9.TMQ02cRwu6hUGI07r_wjsTbz7Z6FBQPyrSOn2tZaUL401Yd6SqzRhe4FM_LBSG6Qju7bEdbH-J5PcnWsNoLnptr27c62jxl2LOw_p-jOPJrqHK8wrTODhH6Pu58KTmklnGovBUniiyRYipu1eTehuoOc6zaZKq4IYsQOEWWWNTG_jL5_CxD2W7_bLmffxQ49UbwNfkQg3lAZcRBEbB8DYEf8ay3HEEWoeGY5LLLyUnzT9vuEtdJVttvGItQWTTC1k4_ZqNqKzpRabx3utSlv65ZAYZQqDYSV50KsI6CQj9iuBfWtz-JvhzrXvBa3CwJdPFWueaEZNZr5OyB1zFg5NQ'
          end

          response 200 do
            key :description, 'Access token validated, user attributes are serialized and rendered to client'
            schema { key :$ref, :UserAttributesResponse }
          end
        end
      end

      swagger_path '/sign_in/revoke' do
        operation :post do
          key :description, 'Sign in Service session destruction'
          key :operationId, 'postSignInRevoke'
          key :tags, %w[
            authentication
          ]

          key :produces, ['text/html']
          key :consumes, ['application/json']

          parameter do
            key :name, 'refresh_token'
            key :in, :path
            key :description, 'Refresh token string, must be URI-encoded'
            key :required, true
            key :type, :string
            key :example, 'v1%3Ainsecure%2Bdata%2BA6ZXlKMWMyVnlYM1YxYVdRaU9pSmtaamt4WWpWa01pMHlaRE14TFRSbE1tSXRZbU16TXkweE1tRTRPRE5sT0ROa05tUWlMQ0p6WlhOemFXOXVYMmhoYm1Sc1pTSTZJalF5TmpZNU5UTmxMVFJrTUdRdE5EVmtZaTA1TWpOaUxUSTJaV1E0WVdJeVpXUXpPQ0lzSW5CaGNtVnVkRjl5WldaeVpYTm9YM1J2YTJWdVgyaGhjMmdpT2lJd00yWTJPR015TkRRMk16VmpOek00WkRkaE56a3lNV0ZsWm1JME0yWTFPVEF4WTJKaU9UUTJOVFJoTkRobU5XRXhPVFkwTjJVNE16ZzFaVGd6TlRJeklpd2lZVzUwYVY5amMzSm1YM1J2YTJWdUlqb2lORGsxTlRWaE5EY3haalZsWVRKbE1UaGlabUkwTmpKbU5ESTNabUZpTTJNaUxDSnViMjVqWlNJNkltSm1Namt5WlRFek9HRmxabU00TXprelltVTBNMkZrTVdZellqUXpZVGMySWl3aWRtVnljMmx2YmlJNklsWXdJaXdpZG1Gc2FXUmhkR2x2Ymw5amIyNTBaWGgwSWpwdWRXeHNMQ0psY25KdmNuTWlPbnQ5ZlE9PQ%3D%3D.bf292e138aefc8393be43ad1f3b43a76.V0'
          end

          parameter do
            key :name, 'anti_csrf_token'
            key :in, :path
            key :description, 'Anti CSRF token, used to match `refresh` calls with the `token` call that generated the refresh token used - currently disabled, this can be ignored'
            key :required, false
            key :type, :string
            key :example, '7c8f362f4589433314d6dc8e6378800d'
          end

          response 200 do
            key :description, 'Refresh_token validated, then session is destroyed, invalidating connected tokens'
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
