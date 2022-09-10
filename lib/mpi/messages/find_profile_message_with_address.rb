# frozen_string_literal: true

require_relative 'find_profile_message_fields'
require_relative 'find_profile_message_with_address_fields'
require_relative 'find_profile_message_helpers'
require 'mpi/constants'

module MPI
  module Messages
    class FindProfileMessageWithAddress
      include FindProfileMessageHelpers
      attr_reader :address, :given_names, :family_name, :birth_date, :gender, :search_type

      def initialize(profile)
        required_fields_present?(profile)
        @given_names = profile[:given_names]
        @family_name = profile[:last_name]
        @birth_date = profile[:birth_date]
        # gender is optional and will default to nil if it DNE
        @gender = profile[:gender]

        @address = profile[:address]
        @street_address_lines = [address['addressLine1'], address['addressLine2'], address['addressLine3']].compact
        @city = address['city']
        @state = address['stateCode'] || ''
        # TODO: add logic for international postal codes
        @postal_code = address['zipCode5']
        @country = address['countryCodeISO2']

        # Hardcode search_type for now, with the option to parameterize it later if needed
        @search_type = MPI::Constants::CORRELATION_WITH_RELATIONSHIP_DATA
      end

      def required_fields_present?(profile)
        fields = FindProfileMessageFields.new(profile)
        fields.validate
        address_fields = FindProfileMessageWithAddressFields.new(profile[:address] || {})
        address_fields.validate

        # Ignore missing values for SSN while still validating for the rest
        fields.missing_keys.delete(:ssn)
        fields.missing_values.delete(:ssn)

        all_missing_keys = fields.missing_keys + address_fields.missing_keys
        all_missing_values = fields.missing_values + address_fields.missing_values

        raise ArgumentError, "required keys are missing: #{all_missing_keys}" if all_missing_keys.present?

        if all_missing_values.present?
          raise ArgumentError,
                "required values are missing for keys: #{all_missing_values}"
        end
      end

      private

      # This is the same as build_parameter_list in MPI::Messages::FindProfileMessages,
      # except it swaps out build_living_subject_id, which uses SSN, for build_patient_address.
      def build_parameter_list
        el = element('parameterList')
        el << build_gender if @gender.present?
        el << build_living_subject_birth_time
        el << build_living_subject_name
        el << build_patient_address
        el << build_vba_orchestration if Settings.mvi.vba_orchestration
        el
      end

      def build_control_act_process
        el = element('controlActProcess', classCode: 'CACT', moodCode: 'EVN')
        el << element('code', code: 'PRPA_TE201305UV02', codeSystem: '2.16.840.1.113883.1.6')
      end
    end
  end
end
