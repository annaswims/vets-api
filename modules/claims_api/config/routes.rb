# frozen_string_literal: true

ClaimsApi::Engine.routes.draw do
  get '/metadata', to: 'metadata#index'
  get '/:version/upstream_healthcheck', to: 'upstream_healthcheck#index', defaults: { format: 'json' }
  match '/v1/*path', to: 'application#cors_preflight', via: [:options]

  namespace :v1, defaults: { format: 'json' } do
    mount OkComputer::Engine, at: '/healthcheck'

    resources :claims, only: %i[index show]
    namespace :forms do
      ## 526 Forms
      get '526', to: 'disability_compensation#schema'
      post '526', to: 'disability_compensation#submit_form_526'
      put '526/:id', to: 'disability_compensation#upload_form_526'
      post '526/validate', to: 'disability_compensation#validate_form_526'
      post '526/:id/attachments', to: 'disability_compensation#upload_supporting_documents'
      ## 0966 Forms
      get '0966', to: 'intent_to_file#schema'
      post '0966', to: 'intent_to_file#submit_form_0966'
      get '0966/active', to: 'intent_to_file#active'
      post '0966/validate', to: 'intent_to_file#validate'
      ## 2122 Forms
      get '2122', to: 'power_of_attorney#schema'
      post '2122', to: 'power_of_attorney#submit_form_2122'
      get '2122/active', to: 'power_of_attorney#active'
      put '2122/:id', to: 'power_of_attorney#upload'
      get '2122/:id', to: 'power_of_attorney#status'
      post '2122/validate', to: 'power_of_attorney#validate'
    end
  end

  namespace :v2, defaults: { format: 'json' } do
    mount OkComputer::Engine, at: '/healthcheck'

    post '/veteran-id:find', to: 'veteran_identifier#find', constraints: { find: /:find/ }
    namespace :veterans do
      get '/:veteranId/claims', to: 'claims#index'
      get '/:veteranId/claims/:id', to: 'claims#show'
      post '/:veteranId/claims/:id/5103', to: 'evidence_waiver#submit'
      get '/:veteranId/power-of-attorney', to: 'power_of_attorney#show'
      put '/:veteranId/power-of-attorney:appoint-organization', to: 'power_of_attorney#appoint_organization',
                                                                constraints: { 'appoint-organization': /:appoint-organization/ } # rubocop:disable Layout/LineLength
      put '/:veteranId/power-of-attorney:appoint-individual', to: 'power_of_attorney#appoint_individual',
                                                              constraints: { 'appoint-individual': /:appoint-individual/ } # rubocop:disable Layout/LineLength
      get '/:veteranId/intent-to-files/:type',
          to: 'intent_to_files#type',
          constraints: (lambda do |request|
            ClaimsApi::V2::Veterans::IntentToFilesController::ITF_TYPES.include?(request.path_parameters[:type])
          end)
      post '/:veteranId/intent-to-files', to: 'intent_to_files#submit'
    end
  end

  namespace :docs do
    mount Rswag::Ui::Engine => 'swagger'

    namespace :v1 do
      get 'api', to: 'api#index'
    end

    namespace :v2 do
      get 'api', to: 'api#index'
    end
  end
end
