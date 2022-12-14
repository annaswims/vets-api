# frozen_string_literal: true

module Mobile
  module ListFilter
    class Filter

      ALLOWED_OPERATIONS = %i[eq notEq].freeze

      def initialize(collection, filters)
        @collection = collection
        @filters = filters
      end

      def self.matches(collection, filters)
        filterer = new(collection, filters)
        filterer.result
      end

      def result
        # may also need to add any errors and metadata, but it doesn't seem like the metadata really does anything
        Common::Collection.new(data: matches, metadata: @collection.metadata, errors: @collection.errors)
      end

      private

      def matches
        @collection.data.select { |record| matches_filters?(record) }
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