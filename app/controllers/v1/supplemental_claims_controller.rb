# frozen_string_literal: true

module V1
  class SupplementalClaimsController < AppealsBaseControllerV1
    def show
      render json: decision_review_service.get_supplemental_claim(params[:id]).body
    rescue => e
      log_exception_to_personal_information_log(
        e, error_class: error_class(method: 'show', exception_class: e.class), id: params[:id]
      )
      raise
    end

    def create
      sc_create = decision_review_service.create_supplemental_claim(request_body: request_body_hash, user: @current_user)
      render json: sc_create
    rescue => e
      request = begin
        { body: request_body_hash }
      rescue
        request_body_debug_data
      end
      
      log_exception_to_personal_information_log(
        e, error_class: error_class(method: 'create', exception_class: e.class), request: request
      )
      raise
    end

    private

    def error_class(method:, exception_class:)
      "#{self.class.name}##{method} exception #{exception_class} (SC_V1)"
    end
  end
end
