# frozen_string_literal: true

require 'sm/client'

module MyHealth
  class SMController < ApplicationController
    include ActionController::Serialization
    include MyHealth::MHVControllerConcerns

    skip_before_action :authenticate

    protected

    def client
      # @client ||= SM::Client.new(session: { user_id: current_user.mhv_correlation_id })
      # @client ||= SM::Client.new(session: { user_id: 9792157 }) # STAGING USER
      # @client ||= SM::Client.new(session: { user_id: 1571704 }) # DEV USER
      @client ||= SM::Client.new(session: { user_id: 7366505 }) # SYST MHV smautotest4
    end

    def authorize
      # raise_access_denied unless current_user.authorize(:mhv_messaging, :access?)
    end

    def raise_access_denied
      raise Common::Exceptions::Forbidden, detail: 'You do not have access to messaging'
    end

    def use_cache?
      params[:useCache]&.downcase == 'true'
    end
  end
end
