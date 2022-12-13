# frozen_string_literal: true

module Mobile
  module ListFilter
    class Filter

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

      # private

      # def call
      #   filters = filters.map(&:to_unsafe_hash)
      #   filters = gather_filters(filters)
      #   filter_records
      # end




      # needs to be per operation
      def filter_records
        @filters.each_pair do |match_attribute, remainder|
          # ugliness
          operation = remainder.keys.first
          value = remainder.keys.first

          case operation
          when :eq
            @records.filter! { |r| r[match_attribute.to_sym] == v }
          when :notEq
            @records.filter! { |r| r[match_attribute.to_sym] != v }
          end
        end
      end
    end
  end
end