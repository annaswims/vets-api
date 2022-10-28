# frozen_string_literal: true

require 'ihub/appointments/service'
require 'ddtrace'

module V0
  class AppointmentsController < ApplicationController
    def index
      Datadog::Tracing.trace('Appointments#Index Web') do
        response = service.appointments

        render json: response, serializer: AppointmentSerializer
      end
    end

    private

    def service
      IHub::Appointments::Service.new @current_user
    end
  end
end
