# frozen_string_literal: true

module V2
  class HigherLevelReviewsController < AppealsBaseController
    def show
      render json: decision_review_service_v2.get_higher_level_review(params[:id]).body
    rescue => e
      log_exception_to_personal_information_log(
        e, error_class: error_class(method: 'show', exception_class: e.class), id: params[:id]
      )
      raise
    end

    def create
      hlr_create = decision_review_service_v2.create_higher_level_review(request_body: request_body_hash,
                                                                         user: @current_user)
      render json: hlr_create
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
      "#{self.class.name}##{method} exception #{exception_class} (HLR_V1)"
    end
  end
end
