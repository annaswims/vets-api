# frozen_string_literal: true

require 'rails_helper'

describe VirtualAgentSendUserInfoJob, type: :job do
  describe '#perform' do
    it 'reads from user records table' do

      # create test instance of record collection
      # https://devhints.io/factory_bot
      # factory defined here: spec/factories/create_virtual_agent_user_access_records.rb
      # FactoryBot.build(:create_virtual_agent_user_access_record)

      # instead of using a double, 
      # use allow(VirtualAgentUserAccessRecord).to receive(:all) { user_record_collection}
      # to mock the return of the table read
      user_record_collection = double
      expect(VirtualAgentUserAccessRecord).to receive(:all) { user_record_collection }
      
      puts user_record
      VirtualAgentSendUserInfoJob.new.perform()
    end
  end
end
