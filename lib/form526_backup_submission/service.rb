# frozen_string_literal: true

require 'common/client/base'
require 'common/client/concerns/monitoring'
require 'common/client/errors'
require 'common/exceptions/forbidden'
require 'common/exceptions/schema_validation_errors'
require 'form526_backup_submission/configuration'
require 'form526_backup_submission/service_exception'

module Form526BackupSubmission
  ##
  # Proxy Service for the Lighthouse Decision Reviews API.
  #
  class Service < Common::Client::Base
    include SentryLogging
    include Common::Client::Concerns::Monitoring

    configuration Form526BackupSubmission::Configuration

    REQUIRED_CREATE_HEADERS = %w[X-VA-First-Name X-VA-Last-Name X-VA-SSN X-VA-Birth-Date].freeze
    
    def get_upload_location
      headers = {}
      request_body = {}
      response = perform :post, 'uploads', request_body, headers
      return response
    end

  end
end
