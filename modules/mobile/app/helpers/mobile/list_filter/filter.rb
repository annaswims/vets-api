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
        filterer.result
      end

      def result
        # may also need to add any errors and metadata, but it doesn't seem like the metadata really does anything
        Common::Collection.new(data: matches)
      end

      private

      def matches
        @records.data.select { |record| matches_filters?(record) }
      end

      def matches_filters?(record)
        @filters.all? do |match_attribute, remainder|
          # ugliness. perhaps at least validate that there is only one key
          operation = remainder.keys.first
          value = remainder.values.first

          case operation
          when :eq
            record[match_attribute.to_sym] == value
          when :notEq
            record[match_attribute.to_sym] != value
          end
        end
      end
    end
  end
end