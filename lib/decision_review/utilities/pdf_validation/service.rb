# frozen_string_literal: true

require 'decision_review/utilities/pdf_validation/configuration'

module DecisionReview
  ##
  # Proxy Service for the Lighthouse PDF validation endpoint.
  #
  module PdfValidation
    class Service < Common::Client::Base
      include SentryLogging
      include Common::Client::Concerns::Monitoring

      configuration DecisionReview::PdfValidation::Configuration

      LH_ERROR_KEY = 'errors'
      LH_ERROR_DETAIL_KEY = 'detail'
      POST_HEADERS = { 'Content-Type' => 'application/pdf', 'Transfer-Encoding' => 'chunked' }

      def validate_pdf_with_lighthouse(file)
        perform(:post, 'uploads/validate_document', file.read, POST_HEADERS)
                
      rescue => e
        raise Common::Exceptions::UnprocessableEntity.new(
          detail: e.body[LH_ERROR_KEY].map { |d| d[LH_ERROR_DETAIL_KEY] }.join("\n"),
          source: 'FormAttachment.lighthouse_validation'
        )
      end

    end
  end
end