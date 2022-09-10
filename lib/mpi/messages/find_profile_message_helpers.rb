# frozen_string_literal: true

require 'ox'
require_relative 'message_builder'
require_relative 'find_candidate_message_error'

module MPI
  module Messages
    module FindProfileMessageHelpers
      include MPI::Messages::MessageBuilder
      EXTENSION = 'PRPA_IN201305UV02'

      def to_xml
        super(EXTENSION, build_body)
      rescue => e
        Rails.logger.error "failed to build find candidate message: #{e.message}"
        raise
      end

      private

      def build_body
        body = build_control_act_process
        body << query_by_parameter
        body
      end

      def query_by_parameter
        build_query_by_parameter << build_parameter_list
      end

      def build_query_by_parameter
        el = element('queryByParameter')
        el << element('queryId', root: '1.2.840.114350.1.13.28.1.18.5.999', extension: '18204')
        el << element('statusCode', code: 'new')
        el << element('modifyCode', code: search_type)
        el << element('initialQuantity', value: 1)
      end

      def build_gender
        el = element('livingSubjectAdministrativeGender')
        el << element('value', code: @gender)
        el << element('semanticsText', text!: 'Gender')
        el
      end

      def build_living_subject_birth_time
        el = element('livingSubjectBirthTime')
        el << element('value', value: Date.parse(@birth_date)&.strftime('%Y%m%d'))
        el << element('semanticsText', text!: 'Date of Birth')
        el
      end

      def build_living_subject_id
        el = element('livingSubjectId')
        el << element('value', root: '2.16.840.1.113883.4.1', extension: @ssn)
        el << element('semanticsText', text!: 'SSN')
        el
      end

      def build_living_subject_name
        el = element('livingSubjectName')
        value = element('value', use: 'L')
        @given_names.each do |given_name|
          value << element('given', text!: given_name)
        end
        value << element('family', text!: @family_name)
        el << value
        el << element('semanticsText', text!: 'Legal Name')
        el
      end

      def build_patient_address
        el = element('PatientAddress')
        value = element('value', use: 'PHYS')
        @street_address_lines.each do |street_address_line|
          value << element('streetAddressLine', text!: street_address_line)
        end
        value << element('city', text!: @city)
        value << element('state', text!: @state)
        value << element('postalCode', text!: @postal_code)
        value << element('country', text!: @country)
        el << value
        el << element('semanticsText', text!: 'Physical Address')
        el
      end

      def build_vba_orchestration
        el = element('otherIDsScopingOrganization')
        el << element('value', extension: 'VBA', root: '2.16.840.1.113883.4.349')
        el << element('semanticsText', text!: 'MVI.ORCHESTRATION')
      end
    end
  end
end
