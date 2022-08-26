# frozen_string_literal: true

require 'caseflow/service'
require 'decision_review_v2/service'

class AppealsBaseControllerV2 < AppealsBaseControllerV1
  private

  def decision_review_service
    DecisionReviewV2::Service.new
  end
end
