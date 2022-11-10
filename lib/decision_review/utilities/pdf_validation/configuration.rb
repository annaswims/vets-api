# frozen_string_literal: true

module DecisionReview
  module PdfValidation
    class Configuration < Common::Client::Configuration::REST
      ##
      # @return [String] Base path for decision review URLs.
      #
      def base_path
        Settings.decision_review.pdf_validation.url
      end

      ##
      # @return [String] Service name to use in breakers and metrics.
      #
      def service_name
        'DecisionReview::PDFValidation'
      end

      ##
      # @return [Hash] The basic headers required for any decision review API call.
      #
      def self.base_request_headers
        super.merge('apiKey' => Settings.decision_review.api_key)
      end

      ##
      # Creates the a connection with parsing json and adding breakers functionality.
      #
      # @return [Faraday::Connection] a Faraday connection instance.
      #
      def connection
        @conn ||= Faraday.new(base_path, headers: base_request_headers, request: request_options) do |faraday|
          faraday.use      :breakers
          faraday.use      Faraday::Response::RaiseError

          faraday.response :betamocks if mock_enabled?
          faraday.response :json
          faraday.adapter Faraday.default_adapter
        end
      end

      ##
      # @return [Boolean] Should the service use mock data in lower environments.
      #
      def mock_enabled?
        Settings.decision_review.mock || false
      end

      def breakers_error_threshold
        80 # breakers will be tripped if error rate reaches 80% over a two minute period.
      end
    end
  end
end
