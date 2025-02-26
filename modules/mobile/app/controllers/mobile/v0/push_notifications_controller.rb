# frozen_string_literal: true

require 'vetext/service'

module Mobile
  module V0
    class PushNotificationsController < ApplicationController
      def register
        result = service.register(
          get_app_name(params),
          params[:device_token],
          @current_user.icn,
          params[:os_name],
          params[:device_name] || params[:os_name]
        )

        Rails.logger.info('Mobile Push Register Success', endpoint_sid: result.body[:sid])
        render json: Mobile::V0::PushRegisterSerializer.new(params[:app_name], result.body[:sid])
      end

      def get_prefs
        Rails.logger.info('Mobile Push Call Get Prefs', endpoint_sid: params[:endpoint_sid])
        render json: Mobile::V0::PushGetPrefsSerializer.new(params[:endpoint_sid],
                                                            service.get_preferences(params[:endpoint_sid]).body)
      end

      def set_pref
        Rails.logger.info('Mobile Push Call Set Prefs', endpoint_sid: params[:endpoint_sid])
        service.set_preference(params[:endpoint_sid], params[:preference], params[:enabled].to_s.downcase == 'true')

        render json: {}, status: :ok
      end

      def send_notification
        Rails.logger.info('Mobile Push Call Send', icn: @current_user.icn, template_id: params[:template_id])
        service.send_notification(
          get_app_name(params), @current_user.icn, params[:template_id], params[:personalization]
        )

        render json: {}, status: :ok
      end

      private

      def service
        @service ||= VEText::Service.new
      end

      def get_app_name(params)
        "#{params[:app_name]}#{params[:debug] ? '_debug' : ''}"
      end
    end
  end
end
