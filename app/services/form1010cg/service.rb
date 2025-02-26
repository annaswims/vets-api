# frozen_string_literal: true

# This service manages the interactions between CaregiversAssistanceClaim, CARMA, and Form1010cg::Submission.

require 'carma/client/mule_soft_client'
require 'carma/models/submission'
require 'carma/models/attachments'
require 'mpi/service'
require 'emis/service'

module Form1010cg
  class Service
    extend Forwardable
    include SentryLogging

    class InvalidVeteranStatus < StandardError
    end

    attr_accessor :claim, # SavedClaim::CaregiversAssistanceClaim
                  :submission # Form1010cg::Submission

    NOT_FOUND = 'NOT_FOUND'
    AUDITOR = Form1010cg::Auditor.new

    def self.collect_attachments(claim)
      poa_attachment_id   = claim.parsed_form['poaAttachmentId']
      claim_pdf_path      = claim.to_pdf(sign: true)
      poa_attachment_path = nil

      if poa_attachment_id
        attachment = Form1010cg::Attachment.find_by(guid: claim.parsed_form['poaAttachmentId'])
        poa_attachment_path = attachment.to_local_file if attachment
      end

      [claim_pdf_path, poa_attachment_path]
    end

    def_delegator self, :carma_client # make accessible as instance method

    def self.carma_client
      client = Flipper.enabled?(:caregiver_mulesoft) ? CARMA::Client::MuleSoftClient.new : CARMA::Client::Client.new
      Rails.logger.info "[10-10CG] Using #{client.class} for submissions"
      client
    end

    def initialize(claim, submission = nil)
      # This service makes assumptions on what data is present on the claim
      # Make sure the claim is valid, so we can be assured the required data is present.
      claim.valid? || raise(Common::Exceptions::ValidationErrors, claim)

      # The CaregiversAssistanceClaim we are processing with this service
      @claim        = claim

      # The Form1010cg::Submission
      @submission   = submission

      # Store for the search results we will run on MVI and eMIS
      @cache = {
        # [form_subject]: String          - The person's ICN
        # [form_subject]: NOT_FOUND       - This person could not be found in MVI
        # [form_subject]: nil             - An MVI search has not been conducted for this person
        icns: {},
        # [form_subject]: true            - This person is a veteran
        # [form_subject]: false           - This person's veteran status cannot be confirmed
        # [form_subject]: nil             - An eMIS search has not been conducted for this person
        veteran_statuses: {}
      }
    end

    def process_claim_v2!
      payload = CARMA::Models::Submission.from_claim(claim, build_metadata).to_request_payload

      claim_pdf_path, poa_attachment_path = self.class.collect_attachments(claim)
      payload[:records] = generate_records(claim_pdf_path, poa_attachment_path)

      [claim_pdf_path, poa_attachment_path].each { |p| File.delete(p) if p.present? }

      CARMA::Client::MuleSoftClient.new.create_submission_v2(payload)
    end

    # Will raise an error unless the veteran specified on the claim's data can be found in MVI
    #
    # @return [nil]
    def assert_veteran_status
      if icn_for('veteran') == NOT_FOUND
        error = InvalidVeteranStatus.new
        log_exception_to_sentry(error)
        raise error
      end
    end

    # Returns a metadata hash:
    #
    # {
    #   veteran: {
    #     is_veteran: true | false | nil,
    #     icn: String | nil
    #   },
    #   primaryCaregiver?: { icn: String | nil },
    #   secondaryCaregiverOne?: { icn: String | nil },
    #   secondaryCaregiverTwo?: { icn: String | nil }
    # }
    def build_metadata
      # Set the ICN's for each form_subject on the metadata hash
      metadata = claim.form_subjects.each_with_object({}) do |form_subject, obj|
        icn = icn_for(form_subject)
        obj[form_subject.snakecase.to_sym] = {
          icn: icn == NOT_FOUND ? nil : icn
        }
      end

      # Disabling the veteran status search since there is an issue with searching emis
      # for a veteran status using an ICN. Only edipi works. Consider adding this back in
      # once ICN searches work or we refactor our veteran status serach to use the edipi.
      metadata[:veteran][:is_veteran] = false
      metadata
    end

    # Will search MVI for the provided form subject and return (1) the matching profile's ICN or (2) `NOT_FOUND`.
    # The result will be cached and subsequent calls will return the cached value, preventing additional api requests.
    #
    # @param form_subject [String] The key in the claim's data that contains this person's info (ex: "veteran")
    # @return [String | NOT_FOUND] Returns the icn of the form subject if found, and NOT_FOUND otherwise.
    def icn_for(form_subject)
      cached_icn = @cache[:icns][form_subject]
      return cached_icn unless cached_icn.nil?

      form_subject_data = claim.parsed_form[form_subject]

      if form_subject_data['ssnOrTin'].nil?
        log_mpi_search_result form_subject, :skipped
        return @cache[:icns][form_subject] = NOT_FOUND
      end

      response = mpi_service.find_profile(build_user_identity_for(form_subject_data))

      if response.status == 'OK'
        log_mpi_search_result form_subject, :found
        return @cache[:icns][form_subject] = response.profile.icn
      end

      if response.status == 'NOT_FOUND'
        log_mpi_search_result form_subject, :not_found
        return @cache[:icns][form_subject] = NOT_FOUND
      end

      raise response.error if response.error

      @cache[:icns][form_subject] = NOT_FOUND
    end

    # Will search eMIS for the provided form subject and return `true` if the subject is a verteran.
    # The result will be cached and subsequent calls will return the cached value, preventing additional api requests.
    #
    # @param form_subject [String] The key in the claim's data that contains this person's info (ex: "veteran")
    # @return [true | false] Returns `true` if the form subject is a veteran and false otherwise.
    def is_veteran(form_subject) # rubocop:disable Naming/PredicateName
      cached_veteran_status = @cache[:veteran_statuses][form_subject]
      return cached_veteran_status unless cached_veteran_status.nil?

      icn = icn_for(form_subject)

      return @cache[:veteran_statuses][form_subject] = false if icn == NOT_FOUND

      response = emis_service.get_veteran_status(icn: icn)

      is_veteran = response&.items&.first&.title38_status_code == 'V1'

      @cache[:veteran_statuses][form_subject] = is_veteran || false
    end

    private

    def generate_records(claim_pdf_path, poa_attachment_path)
      [
        {
          file_path: claim_pdf_path, document_type: CARMA::Models::Attachment::DOCUMENT_TYPES['10-10CG']
        },
        {
          file_path: poa_attachment_path, document_type: CARMA::Models::Attachment::DOCUMENT_TYPES['POA']
        }
      ].map do |doc_data|
        next if doc_data[:file_path].blank?

        CARMA::Models::Attachment.new(
          doc_data.merge(
            carma_case_id: nil,
            veteran_name: {
              first: claim.parsed_form.dig('veteran', 'fullName', 'first'),
              last: claim.parsed_form.dig('veteran', 'fullName', 'last')
            },
            document_date: claim.created_at, id: nil
          )
        ).to_request_payload.compact
      end.compact
    end

    def mpi_service
      @mpi_service ||= MPI::Service.new
    end

    def emis_service
      @emis_service ||= EMIS::VeteranStatusService.new
    end

    def log_mpi_search_result(form_subject, result)
      self.class::AUDITOR.log_mpi_search_result(
        claim_guid: claim.guid,
        form_subject: form_subject,
        result: result
      )
    end

    # MPI::Service requires a valid UserIdentity to run a search, but only reads the user's attributes.
    # This method will build a valid UserIdentity, so MPI::Service can pluck the name, ssn, dob, and gender.
    #
    # @param form_subject_data [Hash] The data of a specific form subject (ex: claim.parsed_form['veteran'])
    # @return [UserIdentity] A valid UserIdentity for the given form_subject
    def build_user_identity_for(form_subject_data)
      UserIdentity.new(
        first_name: form_subject_data['fullName']['first'],
        middle_name: form_subject_data['fullName']['middle'],
        last_name: form_subject_data['fullName']['last'],
        birth_date: form_subject_data['dateOfBirth'],
        gender: form_subject_data['gender'],
        ssn: form_subject_data['ssnOrTin'],
        email: form_subject_data['email'] || 'no-email@example.com',
        uuid: SecureRandom.uuid,
        loa: {
          current: LOA::THREE,
          highest: LOA::THREE
        }
      )
    end
  end
end
