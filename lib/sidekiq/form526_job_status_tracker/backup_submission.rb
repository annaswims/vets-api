# frozen_string_literal: true
require 'form526_backup_submission/service'
require 'decision_review_v1/utilities/form_4142_processor'
require 'central_mail/datestamp_pdf'
require 'pdf_fill/filler'

module Sidekiq
  module Form526JobStatusTracker
  # rubocop:disable Metrics/ModuleLength
    module BackupSubmission
      class Processor

        attr_reader :submission, :lighthouse_service, :form, :upload_uuid, :upload_location, :upload_info, :zip
        attr_accessor :docs
        # Uses
        # https://developer.va.gov/explore/benefits/docs/benefits?version=current

        FORM_526 = 'form526'
        FORM_526_UPLOADS = 'form526_uploads'
        FORM_4142 = 'form4142'
        FORM_0781 = 'form0781'
        FORM_8940 = 'form8940'
        FLASHES = 'flashes'
        BIRLS_KEY = 'va_eauth_birlsfilenumber'
        EVIDENCE_LOOKUP = {}

        def initialize(submission_id, docs=[])
          @submission = Form526Submission.find(submission_id)
          @docs = docs
          @lighthouse_service = Form526BackupSubmission::Service.new
          @upload_info = lighthouse_service.get_upload_location.body
          @upload_uuid = upload_info.dig('data', 'id')
          @upload_location = upload_info.dig('data', 'attributes', 'location')
          determine_zip
        end

        def process!
          self.gather_docs!
          self.add_meta_data_to_docs!
          self.send_docs_to_central_mail
        end
  
        private

        def received_date
          date = SavedClaim::DisabilityCompensation.find(submission.saved_claim_id).created_at
          date = date.in_time_zone('Central Time (US & Canada)')
          date.strftime('%Y-%m-%d %H:%M:%S')
        end

        def get_meta_data(doc_type)
          auth_info = submission.auth_headers
          return {
            "veteranFirstName": auth_info['va_eauth_firstName'],
            "veteranLastName": auth_info['va_eauth_lastName'],
            "fileNumber":  auth_info['va_eauth_pnid'],
            "zipCode": zip,
            "source": "va.gov backup submission",
            "docType": doc_type,
            "businessLine": "CMP"
          }
        end

        def add_meta_data_to_docs!
          docs.each do |doc|
            doc[:metadata] = get_meta_data(doc[:type])
          end
        end

        def generate_multipart_payload_from_docs
          # TODO
          raise "figure out multipart upload"
          docs.map do |doc|            
            [
              { :file => Faraday::UploadIO.new(doc[:metadata].to_json, "application/json", nil, "Content-Disposition" => 'form-data; name="metadata"') },
              { :file => Faraday::UploadIO.new(doc[:metadata].to_json, "application/pdf", nil, "Content-Disposition" => 'form-data; name="content"') }

          end
        end

        def determine_zip
          z = submission.form.dig('form526', 'form526', 'veteran', 'currentMailingAddress')
          if z.nil? 
            @zip = '00000'
          else
            z_final = z['zipFirstFive']
            z_final += "-#{z['zipLastFour']}" unless z['zipLastFour'].nil?
            @zip = z_final
          end
        end

        def bdd?
          submission.form.dig('form526', 'form526', 'bddQualified') || false
        end

        def get_form526_pdf
          # TODO
        end

        def get_uploads          
          uploads = submission.form[FORM_526_UPLOADS]      
          uploads.each do |upload|
            guid = upload['confirmationCode']
            sea = SupportingEvidenceAttachment.find_by(guid: guid)
            # file_body = sea&.get_file&.read
            file = sea&.get_file
            raise ArgumentError, "supporting evidence attachment with guid #{guid} has no file data" if file.nil?
            docs << upload.merge!(file: file, type: EVIDENCE_LOOKUP[upload['attachmentId']] )
          end
        end

        def get_form4142_pdf
          processor_4142 = DecisionReviewV1::Processor::Form4142Processor.new(form_data: submission.form[FORM_4142], response: upload_info)
          docs << {
            type: '21-4142',
            file: processor_4142.pdf_path
          }
        end

        def get_form0781_pdf
          # refactor away from EVSS eventually
          files = EVSS::DisabilityCompensationForm::SubmitForm0781.new.get_docs(submission.id, upload_uuid)   
          docs.concat(files)
        end

        def get_form8940_pdf
          # refactor away from EVSS eventually
          files = EVSS::DisabilityCompensationForm::SubmitForm8940.new.get_docs(submission.id, upload_uuid)
          docs << files
        end

        def get_bdd_pdf
          # Move away from EVSS at later date
          docs << {
            type: 'bdd',
            file: 'lib/evss/disability_compensation_form/bdd_instructions.pdf'
          }
        end

        def gather_docs!
          # get_form526_pdf      # 21-526EZ    
          get_uploads      if submission.form[FORM_526_UPLOADS]      
          get_form4142_pdf if submission.form[FORM_4142]
          get_form0781_pdf if submission.form[FORM_0781]
          get_form8940_pdf if submission.form[FORM_8940]
          get_bdd_pdf      if bdd?

          # Not going to support flashes since this JOB could have already worked and be successful
          # Plus if the error is in BGS it wont work anyway
        
        end



      end


      class Enqueue
        include SentryLogging
        include Sidekiq::Worker
        sidekiq_options retry: 15
        
        def perform(failed_values)
          return unless enabled?
          ap "HERE"
          ap failed_values
        end

        private

        def enabled?
          Flipper.enabled?(:form526_submit_to_central_mail_on_exhaustion)
        end
      end
    end
  end
end