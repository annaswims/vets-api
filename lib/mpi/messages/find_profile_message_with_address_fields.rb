# frozen_string_literal: true

module MPI
  module Messages
    # validates the fields used to find profile messages
    class FindProfileMessageWithAddressFields
      attr_reader :missing_keys, :missing_values

      REQUIRED_ADDRESS_FIELDS = %w[
        addressLine1
        city
        zipCode5
        countryName
      ].freeze

      def initialize(address)
        @address = address
      end

      def valid?
        @missing_keys.blank? && @missing_values.blank?
      end

      def validate
        @missing_keys = REQUIRED_ADDRESS_FIELDS - @address.keys
        @missing_values = REQUIRED_ADDRESS_FIELDS.select { |key| @address[key].nil? || @address[key].blank? }
      end
    end
  end
end
