# frozen_string_literal: true

module AppealsApi
  class ApplicationController < ::ApplicationController
    skip_before_action :verify_authenticity_token
    skip_after_action :set_csrf_header
    before_action :deactivate_endpoint

    def render_response(response)
      render json: response.body, status: response.status
    end

    def deactivate_endpoint
      return unless sunset_date

      if sunset_date.today? || sunset_date.past?
        render json: {
          errors: [
            {
              title: 'Not found',
              detail: "There are no routes matching your request: #{request.path}",
              code: '411',
              status: '404'
            }
          ]
        }, status: :not_found
      end
    end

    def sunset_date
      nil
    end

    def set_tags_and_extra_context
      RequestStore.store['additional_request_attributes'] = { 'source' => 'appeals_api' }
      Raven.tags_context(source: 'appeals_api')
    end

    def model_errors_to_json_api(model)
      errors = model.errors.map do |error|
        tpath = error.options.delete(:error_tpath) || 'common.exceptions.validation_errors'
        data = I18n.t(tpath).deep_merge error.options
        data[:detail] = error.message
        data[:source] = { pointer: error.attribute.to_s } if error.options[:source].blank?
        data.compact # remove nil keys
      end
      { errors: errors }
    end

    # HEADERS should be a list of header names of interest, defined in the parent
    # controller based on the form schema.
    #
    # @return [Hash<String,String>] request headers of interest as a hash
    def request_headers
      return {} unless defined? self.class::HEADERS

      self.class::HEADERS.index_with { |key| request.headers[key] }.compact
    end
  end
end
