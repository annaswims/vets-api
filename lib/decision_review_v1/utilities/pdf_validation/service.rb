# frozen_string_literal: true

require 'decision_review_v1/utilities/pdf_validation/configuration'

module DecisionReviewV1
  ##
  # Proxy Service for the Lighthouse PDF validation endpoint.
  #
  module PdfValidation
    class Service < Common::Client::Base
      include SentryLogging
      include Common::Client::Concerns::Monitoring

      configuration DecisionReviewV1::PdfValidation::Configuration

      def validate_pdf_with_lighthouse(file)
        perform(:post, 'uploads/validate_document', file.read,
                { 'Content-Type' => 'application/pdf', 'Transfer-Encoding' => 'chunked' })
      rescue => e
        raise Common::Exceptions::UnprocessableEntity.new(
          detail: e.body['errors'].map { |d| d['detail'] }.join("\n"),
          source: 'FormAttachment.lighthouse_validation'
        )
      end

      private

      def rejiggered_lighthouse_return; end
    end
  end
end
