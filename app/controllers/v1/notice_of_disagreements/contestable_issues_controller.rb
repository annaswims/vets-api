# frozen_string_literal: true

module V1
  module NoticeOfDisagreements
    class ContestableIssuesController < AppealsBaseController
      def index
        render json: decision_review_service_v1
          .get_notice_of_disagreement_contestable_issues(user: current_user)
          .body
      rescue => e
        log_exception_to_personal_information_log e,
                                                  error_class: "#{self.class.name}#index exception #{e.class} (NOD_V1)"
        raise
      end
    end
  end
end
