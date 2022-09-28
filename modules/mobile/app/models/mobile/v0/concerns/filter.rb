# frozen_string_literal: true

module Mobile
  module V0
    module Concerns
      class Filter
        PERMITTED_OPERATIONS = %q[orEqual andEqual notEqual]
        attr_reader :records
        def initialize(records)
          @records = records
        end

        def call(filter_params)
          filters = filter_params.map(&:to_unsafe_hash)
          filters = gather_filters(filters)
          filters = validate_request(filters)
          filter_records(filters)
        end

        def self.filter(records, filter_params = {})
          return [] if records.blank?

          filterer = new(records, filter_params)
          filterer.call
          filterer.records
        end

        def gather_filters(filters)
          filters.each_with_object({}) do |requested_params, received_filters|
            filter_name = requested_params.keys.first
            operation = requested_params[filter_name].keys.first
            search_term = requested_params[filter_name][operation]
            filter_pair = { operation: operation, search_term: search_term }

            if received_filters.key?(filter_name)
              received_filters[filter_name] << filter_pair
            else
              received_filters[filtern_name] = [filter_pair]
            end
          end
        end

        def validate_request(filters)
          classes = records.map(&:class).uniq
          raise 'MIXED CLASSES' if classes.count != 1
          unless (classes.first.attribute_names & filters.keys.map(&:to_sym)).count == filters.keys.count
            raise 'NOT FILTERABLE'
          end
          raise 'BAD FILTERS' unless filters.values.all? { |v| v.class.in?([String, Integer]) }
        end

        def filter_records(filters)
          records.filter! { |r| r[k.to_sym] == v }
        end
      end
    end
  end
end
