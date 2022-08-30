# frozen_string_literal: true

module MPI
  module Messages
    class FindProfileMessageWithAddress < FindProfileMessage
      attr_reader :address

      def initialize(profile)
        required_fields_present?(profile)
        @address = profile[:address]
        @street_address_lines = [address['addressLine1'], address['addressLine2'], address['addressLine3']].compact
        @city = address['city']
        @state = address['stateCode'] || ''
        # TODO: add logic for international postal codes
        @postal_code = address['zipCode5']
        @country = address['countryCodeISO2']

        super(profile)
      end

      def required_fields_present?(profile)
        fields = FindProfileMessageFields.new(profile)
        fields.validate
        address_fields = FindProfileMessageWithAddressFields.new(profile[:address])
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
        el << build_address
        el << build_vba_orchestration if Settings.mvi.vba_orchestration
        el
      end

      def build_address
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
        el
      end
    end
  end
end
