# frozen_string_literal: true

module Mobile
  module V0
    module Concerns
      class Filter

        PERMITTED_OPERATIONS = %w[andEqual orEqual notEqual andInclude orInclude notInclude].freeze
        attr_reader :records

        def initialize(records)
          @records = records
          @processed_filters = {
            andEqual: [],
            orEqual: [],
            notEqual: [],
            andInclude: [],
            orInclude: [],
            notInclude: [],
          }
        end

        def call(filter_params)
          filters = filter_params.map(&:to_unsafe_hash)
          filters = gather_filters(filters)
          filters = validate_request(filters)
          filter_records
        end

        def self.filter(records, filter_params = {})
          return [] if records.blank?

          filterer = new(records, filter_params)
          filterer.call
          filterer.records
        end

        private

        def gather_filters(requested_filters)
          requested_filters.each do |filter|
            attribute = requested_filters.keys.first
            operation = requested_filters[attribute].keys.first
            search_term = requested_filters[attribute][operation]
            filter_pair = { attribute: attribute, search_term: search_term }
            # raise if not valid operation
            # raise if model does not have attribute
            if @processed_filters[operation].include?(filter_pair)
              # log error
            end

            @processed_filters[operation] << filter_pair
          end
        end

        def filters_valid?(filters)
          # once you have filters, run 
          # raise unless filter classes.first.has_attribute?(filter_name)
        end

        def validate_request(filters)
          klasses = records.map(&:class).uniq
          raise 'MIXED CLASSES' if klasses.count != 1
          klass = klasses.first
          filter_names = filters.keys.map(&:to_sym)
          unless filter_names.all? { |name| name.in?(klass.attribute_names) }
            raise 'NOT FILTERABLE'
          end
          raise 'BAD FILTERS' unless filters.values.all? { |v| v.class.in?([String, Integer]) }

          # can also validate values againt klass.schema
        end

        # needs to be per operation
        def filter_records

          # @processed_filters.each_pair do |operation, filter_pairs|
          #   case operation
          #   when :andEqual
          #     @records.filter! { |r| r[k.to_sym] == v }
          #   when :orEqual
          #     @records.
          #   end
          # end
        end

        def and_group_ids
          @processed_filters[:andEqual].each do |filter|
            
          end
        end
      end
    end
  end
end
