# frozen_string_literal: true

module Mobile
  module V0
    module Concerns
      class Filter
        PERMITTED_OPERATIONS = %w[orEqual andEqual notEqual andInclude orInclude notInclude].freeze
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

        private

        def gather_filters(filters)
          filters.each_with_object({}) do |requested_params, received_filters|
            attribute = requested_params.keys.first
            operation = requested_params[attribute].keys.first
            search_term = requested_params[attribute][operation]
            filter_pair = { operation: operation, search_term: search_term }

            if received_filters.key?(attribute)
              received_filters[attribute] << filter_pair
            else
              received_filters[attribute] = [filter_pair]
            end
          end
        end

        def filters_valid?(filters)
          # unclear exactly what the rules would be yet. 
        end

        def validate_request(filters)
          classes = records.map(&:class).uniq
          raise 'MIXED CLASSES' if classes.count != 1
          unless (classes.first.attribute_names & filters.keys.map(&:to_sym)).count == filters.keys.count
            raise 'NOT FILTERABLE'
          end
          raise 'BAD FILTERS' unless filters.values.all? { |v| v.class.in?([String, Integer]) }
        end

        # needs to be per operation
        def filter_records(filters)
          filters.each_pair do |attribute, details|
            operation = details[:operation]
            value = details[:value]

            case operation
            when 'andEqual'
              @records.filter! { |r| r[k.to_sym] == v }
            when 'orEqual'
              @records.f
            end
          end
        end

      end
    end
  end
end
