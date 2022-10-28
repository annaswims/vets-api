# frozen_string_literal: true

require_dependency 'mobile/application_controller'
require 'ddtrace'

module Mobile
  module V1
    class UsersController < ApplicationController
      after_action :pre_cache_resources, only: :show

      def show
        Datadog::Tracing.trace('Users#Show Mobile') do
          render json: Mobile::V1::UserSerializer.new(@current_user, options)
        end
      end

      private

      def options
        {
          meta: {
            available_services: Mobile::V0::UserSerializer::SERVICE_DICTIONARY.keys
          }
        }
      end

      def pre_cache_resources
        if Flipper.enabled?(:mobile_precache_appointments)
          Mobile::V0::PreCacheAppointmentsJob.perform_async(@current_user.uuid)
        end
        Mobile::V0::PreCacheClaimsAndAppealsJob.perform_async(@current_user.uuid)
      end
    end
  end
end
