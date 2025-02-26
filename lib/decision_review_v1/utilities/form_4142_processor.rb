# frozen_string_literal: true

module DecisionReviewV1
  module Processor
    class Form4142Processor
      # @return [Pathname] the generated PDF path
      attr_reader :pdf_path

      # @return [Hash] the generated request body
      attr_reader :request_body

      FORM_ID = '21-4142'
      FOREIGN_POSTALCODE = '00000'

      def initialize(form_data:, user:, response:)
        @form = form_data
        @user = user
        @response = response
        @pdf_path = generate_stamp_pdf
        @request_body = {
          'document' => to_faraday_upload,
          'metadata' => generate_metadata
        }
      end

      def generate_stamp_pdf
        pdf = PdfFill::Filler.fill_ancillary_form(
          @form, @response.body['data']['id'], FORM_ID
        )
        stamped_path = CentralMail::DatestampPdf.new(pdf).run(text: 'VA.gov', x: 5, y: 5)
        CentralMail::DatestampPdf.new(stamped_path).run(
          text: 'VA.gov Submission',
          x: 510,
          y: 775,
          text_only: true
        )
      end

      private

      def to_faraday_upload
        Faraday::UploadIO.new(
          @pdf_path,
          Mime[:pdf].to_s
        )
      end

      def generate_metadata
        veteran_full_name = @form['veteranFullName']
        address = @form['veteranAddress']

        {
          'veteranFirstName' => veteran_full_name['first'],
          'veteranLastName' => veteran_full_name['last'],
          'fileNumber' => @form['vaFileNumber'] || @form['veteranSocialSecurityNumber'],
          'receiveDt' => received_date,
          'uuid' => @response.body['data']['id'],
          'zipCode' => address['country'] == 'USA' ? address['postalCode'] : FOREIGN_POSTALCODE,
          'source' => 'VA Forms Group B',
          'hashV' => Digest::SHA256.file(@pdf_path).hexdigest,
          'numberAttachments' => 0,
          'docType' => FORM_ID,
          'numberPages' => PDF::Reader.new(@pdf_path).pages.size
        }.to_json
      end

      def received_date
        date = Time.now.in_time_zone('Central Time (US & Canada)')
        date.strftime('%Y-%m-%d %H:%M:%S')
      end
    end
  end
end
