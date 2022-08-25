# frozen_string_literal: true

module MPI
  module Messages
    class FindProfileMessage
      class FindProfileMessageWithAddress
        # ? given_names is just an array of [user_identity.first_name] and their middle_name if present
        # ? See lib/mpi/service.rb:303

        attr_reader :street_address_lines, :city, :state, :postal_code

        def initialize(profile)
          required_fields_present?(profile)

          # ! I don't think these will be on the profile, so need to get them from elsewhere
          @street_address_lines = profile[:street_address_lines]
          @city = profile[:city]
          @state = profile[:state]
          @postal_code = profile[:postal_code]
          @country = profile[:country]
        end

        def required_fields_present?(profile)
          fields = FindProfileMessageFields.new(profile)
          fields.validate

          raise ArgumentError, "required keys are missing: #{fields.missing_keys}" if fields.missing_keys.present?
          if fields.missing_values.present?
            raise ArgumentError, "required values are missing for keys: #{fields.missing_values}"
          end
        end

        private

        # TODO: add build_patient_address instead of subjectID
        def build_parameter_list
          el = element('parameterList')
          el << build_gender if @gender.present?
          el << build_living_subject_birth_time
          # ! build_living_subject_id uses SSN, so remove it
          # el << build_living_subject_id
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
end

# Reference Data: veteran status query params
# Source: (https://github.com/department-of-veterans-affairs/lighthouse-veteran-confirmation#veteran-status-endpoint)
#
# {
#   "first_name": "Tamara",
#   "last_name": "Ellis",
#   "birth_date": "1967-06-19",
#   "street_address_line1": "BEHIND TAHINI RIVER",
#   "street_address_line2": "Unit 2",
#   "city": "AUSTIN",
#   "state": "TX",
#   "zipcode": "78741",
#   "country": "US",
#   "gender": "F"
# }

# config/mpi_schema/mpi_template.xml:63
# structure of address query param
# see also pg 140 of MPI document:
#   "Search Person Request Sample (Match criteria with person trait data"
#
# <addr use="PHYS">
#   <streetAddressLine>{{ profile.address.street }}</streetAddressLine>
#   <city>{{ profile.address.city }}</city>
#   <state>{{ profile.address.state }}</state>
#   <postalCode>{{ profile.address.postal_code }}</postalCode>
#   <country>{{ profile.address.country }}</country>
# </addr>
