# frozen_string_literal: true

class ClaimsApi::RswagConfig
  def config # rubocop:disable Metrics/MethodLength
    {
      'modules/claims_api/app/swagger/claims_api/v1/swagger.json' => {
        openapi: '3.0.1',
        info: {
          title: 'Benefits Claims',
          version: 'v1',
          termsOfService: 'https://developer.va.gov/terms-of-service',
          description: File.read(ClaimsApi::Engine.root.join('app', 'swagger', 'claims_api', 'description', 'v1.md'))
        },
        tags: [
          {
            name: 'Claims',
            description: <<~VERBIAGE
              Allows authenticated and authorized users to access claims data for a single claim by ID, or for all claims based on Veteran data. No data is returned if the user is not authenticated and authorized.
            VERBIAGE
          },
          {
            name: 'Disability',
            description: 'Used for 526 claims.'
          },
          {
            name: 'Intent to File',
            description: 'Used for 0966 submissions.'
          },
          {
            name: 'Power of Attorney',
            description: 'Used for 21-22 and 21-22a form submissions.'
          }
        ],
        components: {
          securitySchemes: {
            bearer_token: {
              type: :http,
              scheme: :bearer
            },
            productionOauth: {
              type: :oauth2,
              description: 'This API uses OAuth 2 with the authorization code grant flow. [More info](https://developer.va.gov/explore/authorization?api=claims)',
              flows: {
                authorizationCode: {
                  authorizationUrl: 'https://api.va.gov/oauth2/authorization',
                  tokenUrl: 'https://api.va.gov/oauth2/token',
                  scopes: {
                    'claim.read': 'Retrieve claim data',
                    'claim.write': 'Submit claim data'
                  }
                }
              }
            },
            sandboxOauth: {
              type: :oauth2,
              description: 'This API uses OAuth 2 with the authorization code grant flow. [More info](https://developer.va.gov/explore/authorization?api=claims)',
              flows: {
                authorizationCode: {
                  authorizationUrl: 'https://sandbox-api.va.gov/oauth2/authorization',
                  tokenUrl: 'https://sandbox-api.va.gov/oauth2/token',
                  scopes: {
                    'claim.read': 'Retrieve claim data',
                    'claim.write': 'Submit claim data'
                  }
                }
              }
            }
          }
        },
        paths: {},
        basePath: '/services/claims/v1',
        servers: [
          {
            url: 'https://sandbox-api.va.gov/services/claims/{version}',
            description: 'VA.gov API sandbox environment',
            variables: {
              version: {
                default: 'v1'
              }
            }
          },
          {
            url: 'https://api.va.gov/services/claims/{version}',
            description: 'VA.gov API production environment',
            variables: {
              version: {
                default: 'v1'
              }
            }
          }
        ]
      },
      Rswag::TextHelpers.new.claims_api_docs => {
        openapi: '3.0.1',
        info: {
          title: 'Benefits Claims',
          version: 'v2',
          description: File.read(ClaimsApi::Engine.root.join('app', 'swagger', 'claims_api', 'description', 'v2.md'))
        },
        tags: [
          {
            name: 'Veteran Identifier',
            description: "Allows authenticated veterans and veteran representatives to retrieve a veteran's id."
          },
          {
            name: 'Claims',
            description: <<~VERBIAGE
              Allows authenticated and authorized users to access claims data for a given Veteran. No data is returned if the user is not authenticated and authorized.
            VERBIAGE
          }
        ],
        components: {
          securitySchemes: {
            bearer_token: {
              type: :http,
              scheme: :bearer,
              bearerFormat: :JWT
            },
            productionOauth: {
              type: :oauth2,
              description: 'This API uses OAuth 2 with the authorization code grant flow. [More info](https://developer.va.gov/explore/authorization?api=claims)',
              flows: {
                authorizationCode: {
                  authorizationUrl: 'https://api.va.gov/oauth2/authorization',
                  tokenUrl: 'https://api.va.gov/oauth2/token',
                  scopes: {
                    'claim.read': 'Retrieve claim data',
                    'claim.write': 'Submit claim data'
                  }
                }
              }
            },
            sandboxOauth: {
              type: :oauth2,
              description: 'This API uses OAuth 2 with the authorization code grant flow. [More info](https://developer.va.gov/explore/authorization?api=claims)',
              flows: {
                authorizationCode: {
                  authorizationUrl: 'https://sandbox-api.va.gov/oauth2/authorization',
                  tokenUrl: 'https://sandbox-api.va.gov/oauth2/token',
                  scopes: {
                    'claim.read': 'Retrieve claim data',
                    'claim.write': 'Submit claim data'
                  }
                }
              }
            }
          }
        },
        paths: {},
        basePath: '/services/claims/v2',
        servers: [
          {
            url: 'https://sandbox-api.va.gov/services/claims/{version}',
            description: 'VA.gov API sandbox environment',
            variables: {
              version: {
                default: 'v2'
              }
            }
          },
          {
            url: 'https://api.va.gov/services/claims/{version}',
            description: 'VA.gov API production environment',
            variables: {
              version: {
                default: 'v2'
              }
            }
          }
        ]
      }
    }
  end
end
