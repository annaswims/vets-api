# frozen_string_literal: true

require 'appeals_api/form_schemas'

class AppealsApi::HigherLevelReviews::V2::HigherLevelReviewsController < AppealsApi::OAuthApplicationController
  skip_before_action :authenticate, only: %i[schema]
  skip_before_action :verify_oauth_token!, only: %i[schema]
  skip_before_action :verify_oauth_scopes!, only: %i[schema]

  HEADERS = AppealsApi::V2::DecisionReviews::HigherLevelReviewsController::HEADERS
  FORM_NUMBER = '200996_WITH_SHARED_REFS'
  SCHEMA_ERROR_TYPE = Common::Exceptions::DetailedSchemaErrors

  def index
    render json: AppealsApi::V2::DecisionReviews::HigherLevelReviewsController.veteran_hlrs(target_veteran_icn)
  end

  def schema
    render json: AppealsApi::JsonSchemaToSwaggerConverter.remove_comments(
      AppealsApi::FormSchemas.new(
        SCHEMA_ERROR_TYPE,
        schema_version: 'v2'
      ).schema(self.class::FORM_NUMBER)
    )
  end
end
