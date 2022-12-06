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
      perform :post, 'uploads', request_body, headers
    end

    def get_file_path_from_objs(file)
      case file
      when EVSS::DisabilityCompensationForm::Form8940Document
        file.pdf_path
      when CarrierWave::SanitizedFile
        file.file
      else
        file
      end
    end

    def get_file_from_obj(obj)
      obj.is_a?(Hash) ? obj[:file] : obj.file
    end

    def generate_tmp_metadata(metadata)
      json_tmpfile = Tempfile.new('metadata.json', encoding: 'utf-8')
      json_tmpfile.write(metadata.to_s)
      json_tmpfile.rewind
      json_tmpfile
    end

    def get_file_name(file)
      file_with_full_path = get_file_path_from_objs(file)
      File.basename(file_with_full_path)
    end

    def upload_logging_logic(file_with_full_path:, attachments:)
      if file_with_full_path =~ /tmp/
        if Rails.env.production?
          File.delete(file_with_full_path)
          attachments.each(&:delete)
        else
          Rails.logger.info("Would have deleted file #{file_with_full_path} if in production env.")
          attachments.each do |evidence_file|
            to_del = get_file_from_obj(evidence_file)
            Rails.logger.info("Would have deleted file #{to_del} if in production env.")
          end
        end
      end
    end

    def upload_doc(upload_url:, file:, metadata:, attachments: [])
      json_tmpfile = generate_tmp_metadata(metadata)
      file_with_full_path = get_file_name(file)

      params = { metadata: Faraday::UploadIO.new(json_tmpfile.path, Mime[:json].to_s, 'metadata.json'),
                 content: Faraday::UploadIO.new(file_with_full_path, Mime[:pdf].to_s, file_name) }
      attachments.each.with_index do |attachment, i|
        file_path = get_file_path_from_objs(attachment[:file])
        file_name = attachment[:file_name]
        params["attachment#{i + 1}".to_sym] = Faraday::UploadIO.new(file_path, Mime[:pdf].to_s, file_name)
      end

      response = perform :put, upload_url, params, { 'Content-Type' => 'multipart/form-data' }

      upload_logging_logic(file_with_full_path: file_with_full_path, evidence: evidence)

      response
    ensure
      json_tmpfile.close
      json_tmpfile.unlink
    end
  end
end
