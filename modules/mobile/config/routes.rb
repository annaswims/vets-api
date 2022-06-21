# frozen_string_literal: true

Mobile::Engine.routes.draw do
  get '/', to: 'discovery#welcome'
  get '/maintenance-windows', to: 'maintenance_windows#index'

  namespace :v0 do
    get '/appeal/:id', to: 'claims_and_appeals#get_appeal'
    get '/appointment_requests/:appointment_request_id/messages', to: 'appointment_request_messages#index'
    get '/appointments', to: 'appointments#index'
    put '/appointments/cancel/:id', to: 'appointments#cancel'
    get '/appointments/community_care/eligibility/:service_type', to: 'community_care_eligibility#show'
    get '/appointments/va/eligibility', to: 'veterans_affairs_eligibility#show'
    get '/appointments/facility/eligibility', to: 'facility_eligibility#index'
    post '/appointment', to: 'appointments#create'
    get '/claims-and-appeals-overview', to: 'claims_and_appeals#index'
    get '/claim/:id', to: 'claims_and_appeals#get_claim'
    post '/claim/:id/documents', to: 'claims_and_appeals#upload_document'
    post '/claim/:id/documents/multi-image', to: 'claims_and_appeals#upload_multi_image_document'
    post '/claim/:id/request-decision', to: 'claims_and_appeals#request_decision'
    get '/community-care-providers', to: 'community_care_providers#index'
    get '/disability-rating', to: 'disability_rating#index'
    get '/health/immunizations', to: 'immunizations#index'
    get '/health/locations/:id', to: 'locations#show'
    get '/letters', to: 'letters#index'
    get '/letters/beneficiary', to: 'letters#beneficiary'
    post '/letters/:type/download', to: 'letters#download'
    get '/maintenance_windows', to: 'maintenance_windows#index'
    get '/messaging/health/messages/signature', to: 'messages#signature'
    get '/military-service-history', to: 'military_information#get_service_history'
    get '/payment-history', to: 'payment_history#index'
    get '/payment-information/benefits', to: 'payment_information#index'
    put '/payment-information/benefits', to: 'payment_information#update'
    put '/push/register', to: 'push_notifications#register'
    get '/push/prefs/:endpoint_sid', to: 'push_notifications#get_prefs'
    put '/push/prefs/:endpoint_sid', to: 'push_notifications#set_pref'
    post '/push/send', to: 'push_notifications#send_notification'
    get '/user', to: 'users#show'
    get '/user/logout', to: 'users#logout'
    post '/user/addresses', to: 'addresses#create'
    put '/user/addresses', to: 'addresses#update'
    delete '/user/addresses', to: 'addresses#destroy'
    post '/user/addresses/validate', to: 'addresses#validate'
    post '/user/emails', to: 'emails#create'
    put '/user/emails', to: 'emails#update'
    delete '/user/emails', to: 'emails#destroy'
    post '/user/phones', to: 'phones#create'
    put '/user/phones', to: 'phones#update'
    delete '/user/phones', to: 'phones#destroy'
    get '/health/rx/prescriptions', to: 'prescriptions#index'
    put '/health/rx/prescriptions/:id/refill', to: 'prescriptions#refill'
    get '/health/rx/prescriptions/:id/tracking', to: 'prescriptions#tracking'

    scope :messaging do
      scope :health do
        resources :triage_teams, only: [:index], defaults: { format: :json }, path: 'recipients'

        resources :folders, only: %i[index show create destroy], defaults: { format: :json } do
          resources :messages, only: [:index], defaults: { format: :json }
        end

        resources :messages, only: %i[show create destroy], defaults: { format: :json } do
          get :thread, on: :member
          get :categories, on: :collection
          patch :move, on: :member
          post :reply, on: :member
          resources :attachments, only: [:show], defaults: { format: :json }
        end

        resources :message_drafts, only: %i[create update], defaults: { format: :json } do
          post ':reply_id/replydraft', on: :collection, action: :create_reply_draft, as: :create_reply
          put ':reply_id/replydraft/:draft_id', on: :collection, action: :update_reply_draft, as: :update_reply
        end
      end
    end
  end

  namespace :v1 do
    namespace :health do
      namespace :appointments do
        get '/', to: 'appointments#index'
        post '/', to: 'appointments#create'
        get '/requests/:appointment_request_id/messages', to: 'appointment_request_messages#index'
        put '/:id/cancel', to: 'appointments#cancel'
        get '/community-care-providers', to: 'community_care_providers#index'
        get '/facilities-info/:sort', to: 'facilities_info#index'

        scope :eligibility do
          get '/community-care/:service_type', to: 'community_care_eligibility#show'
          get '/va', to: 'veterans_affairs_eligibility#show'
          get '/facility', to: 'facility_eligibility#index'
        end
      end

      scope :messaging do
        resources :triage_teams, only: [:index], defaults: { format: :json }, path: 'recipients'

        resources :folders, only: %i[index show create destroy], defaults: { format: :json } do
          resources :messages, only: [:index], defaults: { format: :json }
        end

        resources :messages, only: %i[show create destroy], defaults: { format: :json } do
          get :thread, on: :member
          get :categories, on: :collection
          patch :move, on: :member
          post :reply, on: :member
          resources :attachments, only: [:show], defaults: { format: :json }
        end

        resources :message_drafts, path: 'message-drafts', only: %i[create update], defaults: { format: :json } do
          post ':reply_id/reply-draft', on: :collection, action: :create_reply_draft, as: :create_reply
          put ':reply_id/reply-draft/:draft_id', on: :collection, action: :update_reply_draft, as: :update_reply
        end
      end
      get '/immunizations', to: 'immunizations#index'
    end

    namespace :benefits do
      get '/appeals/:id', to: 'claims_and_appeals#get_appeal'
      get '/claims-and-appeals-overview', to: 'claims_and_appeals#index'
      get '/disability-rating', to: 'disability_rating#index'

      scope :claims do
        get '/:id', to: 'claims_and_appeals#get_claim'
        post '/:id/documents', to: 'claims_and_appeals#upload_document'
        post '/:id/documents/multi-image', to: 'claims_and_appeals#upload_multi_image_document'
        post '/:id/request-decision', to: 'claims_and_appeals#request_decision'
      end

      scope :letters do
        get '/', to: 'letters#index'
        get '/beneficiary', to: 'letters#beneficiary'
        post '/:type/download', to: 'letters#download'
      end

      scope :payments do
        get '/history', to: 'payment_history#index'
        get '/information', to: 'payment_information#index'
        put '/information', to: 'payment_information#update'
      end
    end

    get '/push/:endpoint_sid/prefs', to: 'push_notifications#get_prefs'
    put '/push/:endpoint_sid/prefs', to: 'push_notifications#set_pref'
    get '/user', to: 'users#show'
    get '/user/military-service-history', to: 'military_information#get_service_history'
  end
end
