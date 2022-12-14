# frozen_string_literal: true

module Mobile
  module ListFilter
    class Filter

      ALLOWED_OPERATIONS = %i[eq notEq].freeze

      attr_reader :records

      def initialize(records, filters)
        @records = records
        @filters = filters
      end

      def self.matches(records, filters)
        filterer = new(records, filters)
        filterer.filter_records
        filterer.records
      end

      def filter_records
        @filters.each_pair do |match_attribute, remainder|
          # ugliness
          operation = remainder.keys.first
          value = remainder.values.first

          case operation
          when :eq
            @records.data.keep_if { |r| r[match_attribute.to_sym] == value }
          when :notEq
            @records.data.keep_if { |r| r[match_attribute.to_sym] != value }
          end
        end
      end
    end
  end
end