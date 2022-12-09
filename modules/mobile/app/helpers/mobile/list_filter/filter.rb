# frozen_string_literal: true

module Mobile
  module ListFilter
    class Filter
      def initialize(list, filter_params)
        @list = list
        @filter_params = filter_params
      end

      def self.matches(list, filter_params)
        filterer = new(list, filter_params)
        filterer.filter
      end

      private

      def call
        filters = filter_params.map(&:to_unsafe_hash)
        filters = gather_filters(filters)
        # move all validations to separate class
        filters = validate_request(filters)
        filter_records
      end

      def self.filter(records, filter_params = {})
        return [] if records.blank?

        filterer = new(records, filter_params)
        filterer.call
        filterer.records
      end

      def gather_filters(requested_filters)
        requested_filters.each do |_filter|
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
        @processed_filters[:equal].each do |filter|
        end
      end
    end
  end
end