# frozen_string_literal: true

module Mobile
  module V0
    module Concerns
      class Filter
        attr_reader :records, :filters
        def initialize(records, filters)
          @records = records
          @filters = filters
        end

        def self.filter(records, filters = {})
          return [] if records.blank?

          filterer = new(records, filters)
          filterer.validate_request
          filterer.filter
          records
        end

        def validate_request
          classes = records.map(&:class).uniq
          raise "MIXED CLASSES" if classes.count != 1
          raise "NOT FILTERABLE" unless (classes.first.attribute_names & filters.keys.map(&:to_sym)).count == filters.keys.count
          raise "BAD FILTERS" if filters.values.any? { |v| !v.class.in? [String, Integer] }
        end

        def filter
          filters.each_pair do |k, v|
            @records.filter! { |r| r[k.to_sym] == v }
          end
        end
      end
    end
  end
end