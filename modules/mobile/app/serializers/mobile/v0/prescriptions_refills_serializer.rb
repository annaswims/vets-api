# frozen_string_literal: true

module Mobile
  module V0
    class PrescriptionsRefillsSerializer
      include FastJsonapi::ObjectSerializer

      set_type :PrescriptionRefills

      attributes :failed_station_list,
                 :successful_station_list,
                 :last_updated_time,
                 :prescription_list,
                 :errors,
                 :info_messages

      def initialize(id, resource)
        super(PrescriptionsRefillStruct.new(id, resource[:failed_station_list], resource[:successful_station_list],
                                            resource[:last_updated_time], resource[:prescription_list],
                                            resource[:errors], resource[:info_messages]))
      end
    end
    PrescriptionsRefillStruct = Struct.new(:id, :failed_station_list, :successful_station_list, :last_updated_time,
                                           :prescription_list,
                                           :errors,
                                           :info_messages)
  end
end
