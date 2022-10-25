# frozen_string_literal: true

require 'common/client/base'
require 'common/client/concerns/monitoring'
require 'common/client/errors'
require 'common/exceptions/forbidden'
require 'common/exceptions/schema_validation_errors'
require 'decision_review_v1/configuration'
require 'decision_review_v1/service_exception'
require 'decision_review_v1/form_4142_processor'

module DecisionReviewV1
  ##
  # Proxy Service for the Lighthouse Decision Reviews API.
  #
  class Service < Common::Client::Base
    include SentryLogging
    include Common::Client::Concerns::Monitoring

    configuration DecisionReviewV1::Configuration

    STATSD_KEY_PREFIX = 'api.decision_review'

    HLR_REQUIRED_CREATE_HEADERS = %w[X-VA-First-Name X-VA-Last-Name X-VA-SSN X-VA-Birth-Date].freeze
    NOD_REQUIRED_CREATE_HEADERS = %w[X-VA-File-Number X-VA-First-Name X-VA-Last-Name X-VA-Birth-Date].freeze
    SC_REQUIRED_CREATE_HEADERS = %w[X-VA-First-Name X-VA-Last-Name X-VA-SSN X-VA-Birth-Date].freeze

    HLR_CREATE_RESPONSE_SCHEMA = VetsJsonSchema::SCHEMAS.fetch 'HLR-CREATE-RESPONSE-200_V1'
    HLR_SHOW_RESPONSE_SCHEMA = VetsJsonSchema::SCHEMAS.fetch 'HLR-SHOW-RESPONSE-200_V1'
    # TODO: rename the imported schema as its shared with Supplemental Claims
    GET_LEGACY_APPEALS_RESPONSE_SCHEMA = VetsJsonSchema::SCHEMAS.fetch 'HLR-GET-LEGACY-APPEALS-RESPONSE-200'

    NOD_CREATE_RESPONSE_SCHEMA = VetsJsonSchema::SCHEMAS.fetch 'NOD-CREATE-RESPONSE-200_V1'
    NOD_SHOW_RESPONSE_SCHEMA = VetsJsonSchema::SCHEMAS.fetch 'NOD-SHOW-RESPONSE-200_V1'

    SC_CREATE_RESPONSE_SCHEMA = VetsJsonSchema::SCHEMAS.fetch 'SC-CREATE-RESPONSE-200_V1'
    SC_SHOW_RESPONSE_SCHEMA = VetsJsonSchema::SCHEMAS.fetch 'SC-SHOW-RESPONSE-200_V1'

    GET_CONTESTABLE_ISSUES_RESPONSE_SCHEMA =
      VetsJsonSchema::SCHEMAS.fetch 'DECISION-REVIEW-GET-CONTESTABLE-ISSUES-RESPONSE-200_V1'

    ##
    # Create a Higher-Level Review
    #
    # @param request_body [JSON] JSON serialized version of a Higher-Level Review Form (20-0996)
    # @param user [User] Veteran who the form is in regard to
    # @return [Faraday::Response]
    #
    def create_higher_level_review(request_body:, user:)
      with_monitoring_and_error_handling do
        headers = create_higher_level_review_headers(user)
        response = perform :post, 'higher_level_reviews', request_body, headers
        raise_schema_error_unless_200_status response.status
        validate_against_schema json: response.body, schema: HLR_CREATE_RESPONSE_SCHEMA,
                                append_to_error_class: ' (HLR_V1)'
        response
      end
    end

    ##
    # Retrieve a Higher-Level Review
    #
    # @param uuid [uuid] A Higher-Level Review's UUID (included in a create_higher_level_review response)
    # @return [Faraday::Response]
    #
    def get_higher_level_review(uuid)
      with_monitoring_and_error_handling do
        response = perform :get, "higher_level_reviews/#{uuid}", nil
        raise_schema_error_unless_200_status response.status
        validate_against_schema json: response.body, schema: HLR_SHOW_RESPONSE_SCHEMA,
                                append_to_error_class: ' (HLR_V1)'
        response
      end
    end

    ##
    # Get Contestable Issues for a Higher-Level Review
    #
    # @param user [User] Veteran who the form is in regard to
    # @param benefit_type [String] Type of benefit the decision review is for
    # @return [Faraday::Response]
    #
    def get_higher_level_review_contestable_issues(user:, benefit_type:)
      with_monitoring_and_error_handling do
        path = "contestable_issues/higher_level_reviews?benefit_type=#{benefit_type}"
        headers = get_contestable_issues_headers(user)
        response = perform :get, path, nil, headers
        raise_schema_error_unless_200_status response.status
        validate_against_schema(
          json: response.body,
          schema: GET_CONTESTABLE_ISSUES_RESPONSE_SCHEMA,
          append_to_error_class: ' (HLR_V1)'
        )
        response
      end
    end

    ##
    # Get Legacy Appeals for either a Higher-Level Review or a Supplemental Claim
    #
    # @param user [User] Veteran who the form is in regard to
    # @return [Faraday::Response]
    #
    def get_legacy_appeals(user:)
      with_monitoring_and_error_handling do
        path = 'legacy_appeals'
        headers = get_legacy_appeals_headers(user)
        response = perform :get, path, nil, headers
        raise_schema_error_unless_200_status response.status
        validate_against_schema(
          json: response.body,
          schema: GET_LEGACY_APPEALS_RESPONSE_SCHEMA,
          append_to_error_class: ' (DECISION_REVIEW_V1)'
        )
        response
      end
    end

    # upstream requirements
    # ^[a-zA-Z\-\/\s]{1,50}$
    # Cannot be missing or empty or longer than 50 characters.
    # Only upper/lower case letters, hyphens(-), spaces and forward-slash(/) allowed
    def self.transliterate_name(str)
      I18n.transliterate(str.to_s).gsub(%r{[^a-zA-Z\-/\s]}, '').strip.first(50)
    end

    ##
    # Create a Notice of Disagreement
    #
    # @param request_body [JSON] JSON serialized version of a Notice of Disagreement Form (10182)
    # @param user [User] Veteran who the form is in regard to
    # @return [Faraday::Response]
    #
    def create_notice_of_disagreement(request_body:, user:)
      with_monitoring_and_error_handling do
        headers = create_notice_of_disagreement_headers(user)
        response = perform :post, 'notice_of_disagreements', request_body, headers
        raise_schema_error_unless_200_status response.status
        validate_against_schema(
          json: response.body, schema: NOD_CREATE_RESPONSE_SCHEMA, append_to_error_class: ' (NOD_V1)'
        )
        response
      end
    end

    ##
    # Retrieve a Notice of Disagreement
    #
    # @param uuid [uuid] A Notice of Disagreement's UUID (included in a create_notice_of_disagreement response)
    # @return [Faraday::Response]
    #
    def get_notice_of_disagreement(uuid)
      with_monitoring_and_error_handling do
        response = perform :get, "notice_of_disagreements/#{uuid}", nil
        raise_schema_error_unless_200_status response.status
        validate_against_schema(
          json: response.body, schema: NOD_SHOW_RESPONSE_SCHEMA, append_to_error_class: ' (NOD_V1)'
        )
        response
      end
    end

    ##
    # Get Contestable Issues for a Notice of Disagreement
    #
    # @param user [User] Veteran who the form is in regard to
    # @return [Faraday::Response]
    #
    def get_notice_of_disagreement_contestable_issues(user:)
      with_monitoring_and_error_handling do
        path = 'contestable_issues/notice_of_disagreements'
        headers = get_contestable_issues_headers(user)
        response = perform :get, path, nil, headers
        raise_schema_error_unless_200_status response.status
        validate_against_schema(
          json: response.body,
          schema: GET_CONTESTABLE_ISSUES_RESPONSE_SCHEMA,
          append_to_error_class: ' (NOD_V1)'
        )
        response
      end
    end

    ##
    # Get the url to upload supporting evidence for a Notice of Disagreement
    #
    # @param nod_uuid [uuid] The uuid of the submited Notice of Disagreement
    # @param file_number [Integer] The file number or ssn
    # @return [Faraday::Response]
    #
    def get_notice_of_disagreement_upload_url(nod_uuid:, file_number:)
      with_monitoring_and_error_handling do
        perform :post, 'notice_of_disagreements/evidence_submissions', { nod_uuid: nod_uuid },
                { 'X-VA-File-Number' => file_number.to_s.strip.presence }
      end
    end

    ##
    # Upload supporting evidence for a Notice of Disagreement
    #
    # @param upload_url [String] The url for the document to be uploaded
    # @param file_path [String] The file path for the document to be uploaded
    # @param metadata_string [Hash] additional data
    #
    # @return [Faraday::Response]
    #
    def put_notice_of_disagreement_upload(upload_url:, file_upload:, metadata_string:)
      content_tmpfile = Tempfile.new(file_upload.filename, encoding: file_upload.read.encoding)
      content_tmpfile.write(file_upload.read)
      content_tmpfile.rewind

      json_tmpfile = Tempfile.new('metadata.json', encoding: 'utf-8')
      json_tmpfile.write(metadata_string)
      json_tmpfile.rewind

      params = { metadata: Faraday::UploadIO.new(json_tmpfile.path, Mime[:json].to_s, 'metadata.json'),
                 content: Faraday::UploadIO.new(content_tmpfile.path, Mime[:pdf].to_s, file_upload.filename) }

      # when we upgrade to Faraday >1.0
      # params = { metadata: Faraday::FilePart.new(json_tmpfile, Mime[:json].to_s, 'metadata.json'),
      #            content: Faraday::FilePart.new(content_tmpfile, Mime[:pdf].to_s, file_upload.filename) }
      with_monitoring_and_error_handling do
        perform :put, upload_url, params, { 'Content-Type' => 'multipart/form-data' }
      end
    ensure
      content_tmpfile.close
      content_tmpfile.unlink
      json_tmpfile.close
      json_tmpfile.unlink
    end

    ##
    # Returns all of the data associated with a specific Notice of Disagreement Evidence Submission.
    #
    # @param guid [uuid] the uuid returned from get_notice_of_disagreement_upload_url
    #
    # @return [Faraday::Response]
    #
    def get_notice_of_disagreement_upload(guid:)
      with_monitoring_and_error_handling do
        perform :get, "notice_of_disagreements/evidence_submissions/#{guid}", nil
      end
    end

    ##
    # Creates a new Supplemental Claim
    #
    # @param request_body [JSON] JSON serialized version of a Supplemental Claim Form (20-0995)
    # @param user [User] Veteran who the form is in regard to
    # @return Hash
    #
    def create_supplemental_claim(request_body:, user:)
      results = {}
      lh_data_key = 'data'
      cm_data_key = 'form4142'
      with_monitoring_and_error_handling do
        request_body_obj = JSON.parse(request_body)
        form4142 = request_body_obj.delete(cm_data_key)
        results[lh_data_key] = process_lighthouse_supplemental_form_submission(request_body: request_body_obj, user: user)
        results[cm_data_key] = process_form4142_submission(form4142: form4142, user: user, response: results[lh_data_key]) unless form4142.nil?
      end
      ret = {}
      results.map do |data_key, response|
        ret[data_key] = {
          'body': response.body,
          'status': response.status
        }
      end
      return ret
    end

    ##
    # Returns all of the data associated with a specific Supplemental Claim.
    #
    # @param uuid [uuid] supplemental Claim UUID
    # @return [Faraday::Response]
    #
    def get_supplemental_claim(uuid)
      with_monitoring_and_error_handling do
        response = perform :get, "supplemental_claims/#{uuid}", nil
        raise_schema_error_unless_200_status response.status
        validate_against_schema json: response.body, schema: SC_SHOW_RESPONSE_SCHEMA, append_to_error_class: ' (SC_V1)'
        response
      end
    end

    ##
    # Returns all issues associated with a Veteran that have
    # been decided as of the receiptDate.
    # Not all issues returned are guaranteed to be eligible for appeal.
    #
    # @param user [User] Veteran who the form is in regard to
    # @param benefit_type [String] Type of benefit the decision review is for
    # @return [Faraday::Response]
    #
    def get_supplemental_claim_contestable_issues(user:, benefit_type:)
      with_monitoring_and_error_handling do
        path = "contestable_issues/supplemental_claims?benefit_type=#{benefit_type}"
        headers = get_contestable_issues_headers(user)
        response = perform :get, path, nil, headers
        raise_schema_error_unless_200_status response.status
        validate_against_schema(
          json: response.body,
          schema: GET_CONTESTABLE_ISSUES_RESPONSE_SCHEMA,
          append_to_error_class: ' (SC_V1)'
        )
        response
      end
    end

    ##
    # Get the url to upload supporting evidence for a Supplemental Claim
    #
    # @param sc_uuid [uuid] associated Supplemental Claim UUID
    # @param ssn [Integer] veterans ssn
    # @return [Faraday::Response]
    #
    def get_supplemental_claim_upload_url(sc_uuid:, ssn:)
      with_monitoring_and_error_handling do
        perform :post, 'supplemental_claims/evidence_submissions', { sc_uuid: sc_uuid },
                { 'X-VA-SSN ' => ssn.to_s.strip.presence }
      end
    end

    ##
    # Upload supporting evidence for a Supplemental Claim
    #
    # @param upload_url [String] The url for the document to be uploaded
    # @param file_path [String] The file path for the document to be uploaded
    # @param metadata_string [Hash] additional data
    #
    # @return [Faraday::Response]
    #
    def put_supplemental_claim_upload(upload_url:, file_upload:, metadata_string:)
      content_tmpfile = Tempfile.new(file_upload.filename, encoding: file_upload.read.encoding)
      content_tmpfile.write(file_upload.read)
      content_tmpfile.rewind

      json_tmpfile = Tempfile.new('metadata.json', encoding: 'utf-8')
      json_tmpfile.write(metadata_string)
      json_tmpfile.rewind

      params = { metadata: Faraday::UploadIO.new(json_tmpfile.path, Mime[:json].to_s, 'metadata.json'),
                 content: Faraday::UploadIO.new(content_tmpfile.path, Mime[:pdf].to_s, file_upload.filename) }

      # when we upgrade to Faraday >1.0
      # params = { metadata: Faraday::FilePart.new(json_tmpfile, Mime[:json].to_s, 'metadata.json'),
      #            content: Faraday::FilePart.new(content_tmpfile, Mime[:pdf].to_s, file_upload.filename) }
      with_monitoring_and_error_handling do
        perform :put, upload_url, params, { 'Content-Type' => 'multipart/form-data' }
      end
    ensure
      content_tmpfile.close
      content_tmpfile.unlink
      json_tmpfile.close
      json_tmpfile.unlink
    end

    ##
    # Returns all of the data associated with a specific Supplemental Claim Evidence Submission.
    #
    # @param uuid [uuid] supplemental Claim UUID Evidence Submission
    # @return [Faraday::Response]
    #
    def get_supplemental_claim_upload(uuid:)
      with_monitoring_and_error_handling do
        perform :get, "supplemental_claims/evidence_submissions/#{uuid}", nil
      end
    end

    def self.file_upload_metadata(user)
      {
        'veteranFirstName' => transliterate_name(user.first_name),
        'veteranLastName' => transliterate_name(user.last_name),
        'zipCode' => user.zip,
        'fileNumber' => user.ssn.to_s.strip,
        'source' => 'Vets.gov',
        'businessLine' => 'BVA'
      }.to_json
    end

    private

    def benchmark?
      Settings.decision_review.benchmark_performance
    end

    ##
    # Takes a block and runs it. If benchmarking is enabled it will benchmark and return the results.
    # Returns a tuple of what the block returns, and either nil (if benchmarking disabled), or the benchmark results
    #
    # @param block [block] block to run
    # @return [result, benchmark]
    #
    def run_and_benchmark_if_enabled(&block)
      bm = nil
      block_result = nil
      if benchmark?
        bm = Benchmark.measure {
          block_result = block.call
        }
      else
        block_result = block.call
      end
      return [block_result, bm]
    end

    def benchmark_to_log_data_hash(bm)
      {
        benchmark: 
          {
          user: bm.utime,
          system: bm.stime,
          total: bm.total,
          real: bm.real
        }
      }
    end

    def extract_uuid_from_central_mail_message(data) 
      data[/(?<=\[).*?(?=\])/].split(?:).last
    end

    def parse_form412_response_to_log_msg(data, bm=nil)    
      log_data = {
        message: data,
        extracted_uuid: extract_uuid_from_central_mail_message(data)        
      }    
      log_data[:meta] = benchmark_to_log_data_hash(bm) unless bm.nil? 
      return log_data
    end

    def parse_lighthouse_response_to_log_msg(data, bm=nil) 
      log_data = {    
        message: 'Successful Lighthouse Supplemental Claim Submission',      
        lighthouse_submission: {
          id: data['id'],
          appeal_type: data['type'],
          attributes: {
            status: data['attributes']['status'],
            updatedAt:data['attributes']['updatedAt'],
            createdAt: data['attributes']['createdAt']
          }
        }
      }
      log_data[:meta] = benchmark_to_log_data_hash(bm) unless bm.nil?          
      return log_data
    end

    def process_lighthouse_supplemental_form_submission(request_body:, user:)
      headers = create_supplemental_claims_headers(user)
      response, bm = run_and_benchmark_if_enabled do
        perform :post, 'supplemental_claims', request_body, headers
      end
      raise_schema_error_unless_200_status response.status
      validate_against_schema json: response.body, schema: SC_CREATE_RESPONSE_SCHEMA,
                              append_to_error_class: ' (SC_V1)'

      submission_info_message = parse_lighthouse_response_to_log_msg(response.body["data"], bm)
      ::Rails.logger.info(submission_info_message)  
      return response
    end
    
    def process_form4142_submission(form4142:, user:, response:)
      form4142_response = nil
      form4142_response, bm = run_and_benchmark_if_enabled do
          submit_form4142(form_data: form4142, user: user, response: response) 
      end
      form4142_submission_info_message = parse_form412_response_to_log_msg(form4142_response.body, bm)
      ::Rails.logger.info(form4142_submission_info_message)  
      return form4142_response 
    end

    def submit_form4142(form_data:, user:, response:)
      processor = DecisionReviewV1::Processor::Form4142Processor.new(form_data: form_data, user: user,
                                                                     response: response)
      @pdf_path = processor.pdf_path
      response = CentralMail::Service.new.upload(processor.request_body)
    end

    def create_higher_level_review_headers(user)
      headers = {
        'X-VA-SSN' => user.ssn.to_s.strip.presence,
        'X-VA-ICN' => user.icn.presence,
        'X-VA-First-Name' => user.first_name.to_s.strip.first(12),
        'X-VA-Middle-Initial' => middle_initial(user),
        'X-VA-Last-Name' => user.last_name.to_s.strip.first(18).presence,
        'X-VA-Birth-Date' => user.birth_date.to_s.strip.presence,
        'X-VA-File-Number' => nil,
        'X-VA-Service-Number' => nil,
        'X-VA-Insurance-Policy-Number' => nil
      }.compact

      missing_required_fields = HLR_REQUIRED_CREATE_HEADERS - headers.keys
      if missing_required_fields.present?
        raise Common::Exceptions::Forbidden.new(
          source: "#{self.class}##{__method__}",
          detail: { missing_required_fields: missing_required_fields }
        )
      end

      headers
    end

    def create_notice_of_disagreement_headers(user)
      headers = {
        'X-VA-File-Number' => user.ssn.to_s.strip.presence,
        'X-VA-First-Name' => user.first_name.to_s.strip,
        'X-VA-Middle-Initial' => middle_initial(user),
        'X-VA-Last-Name' => user.last_name.to_s.strip.presence,
        'X-VA-Birth-Date' => user.birth_date.to_s.strip.presence,
        'X-VA-ICN' => user.icn.presence
      }.compact

      missing_required_fields = NOD_REQUIRED_CREATE_HEADERS - headers.keys
      if missing_required_fields.present?
        raise Common::Exceptions::Forbidden.new(
          source: "#{self.class}##{__method__}",
          detail: { missing_required_fields: missing_required_fields }
        )
      end

      headers
    end

    def create_supplemental_claims_headers(user)
      headers = {
        'X-VA-SSN' => user.ssn.to_s.strip.presence,
        'X-VA-ICN' => user.icn.presence,
        'X-VA-First-Name' => user.first_name.to_s.strip.first(12),
        'X-VA-Middle-Initial' => middle_initial(user),
        'X-VA-Last-Name' => user.last_name.to_s.strip.first(18).presence,
        'X-VA-Birth-Date' => user.birth_date.to_s.strip.presence
      }.compact

      missing_required_fields = SC_REQUIRED_CREATE_HEADERS - headers.keys
      if missing_required_fields.present?
        raise Common::Exceptions::Forbidden.new(
          source: "#{self.class}##{__method__}",
          detail: { missing_required_fields: missing_required_fields }
        )
      end

      headers
    end

    def middle_initial(user)
      user.middle_name.to_s.strip.presence&.first&.upcase
    end

    def get_contestable_issues_headers(user)
      raise Common::Exceptions::Forbidden.new source: "#{self.class}##{__method__}" unless user.ssn

      {
        'X-VA-SSN' => user.ssn.to_s,
        'X-VA-ICN' => user.icn.presence,
        'X-VA-Receipt-Date' => Time.zone.now.strftime('%Y-%m-%d')
      }
    end

    def get_legacy_appeals_headers(user)
      raise Common::Exceptions::Forbidden.new source: "#{self.class}##{__method__}" unless user.ssn

      {
        'X-VA-SSN' => user.ssn.to_s,
        'X-VA-ICN' => user.icn.presence
      }
    end

    def with_monitoring_and_error_handling(&block)
      with_monitoring(2, &block)
    rescue => e
      handle_error(e)
    end

    def save_error_details(error)
      PersonalInformationLog.create!(
        error_class: "#{self.class.name}#save_error_details exception #{error.class} (DECISION_REVIEW_V1)",
        data: { error: Class.new.include(FailedRequestLoggable).exception_hash(error) }
      )
      Raven.tags_context external_service: self.class.to_s.underscore
      Raven.extra_context url: config.base_path, message: error.message
    end

    def handle_error(error)
      save_error_details error
      source_hash = { source: "#{error.class} raised in #{self.class}" }

      raise case error
            when Faraday::ParsingError
              DecisionReviewV1::ServiceException.new key: 'DR_502', response_values: source_hash
            when Common::Client::Errors::ClientError
              Raven.extra_context body: error.body, status: error.status
              if error.status == 403
                Common::Exceptions::Forbidden.new source_hash
              else
                DecisionReviewV1::ServiceException.new(
                  key: "DR_#{error.status}",
                  response_values: source_hash,
                  original_status: error.status,
                  original_body: error.body
                )
              end
            else
              error
            end
    end

    def validate_against_schema(json:, schema:, append_to_error_class: '')
      errors = JSONSchemer.schema(schema).validate(json).to_a
      return if errors.empty?

      raise Common::Exceptions::SchemaValidationErrors, remove_pii_from_json_schemer_errors(errors)
    rescue => e
      PersonalInformationLog.create!(
        error_class: "#{self.class.name}#validate_against_schema exception #{e.class}#{append_to_error_class}",
        data: {
          json: json, schema: schema, errors: errors,
          error: Class.new.include(FailedRequestLoggable).exception_hash(e)
        }
      )
      raise
    end

    def raise_schema_error_unless_200_status(status)
      return if status == 200

      raise Common::Exceptions::SchemaValidationErrors, ["expecting 200 status received #{status}"]
    end

    def remove_pii_from_json_schemer_errors(errors)
      errors.map { |error| error.slice 'data_pointer', 'schema', 'root_schema' }
    end
  end
end
