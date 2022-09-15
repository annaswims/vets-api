# frozen_string_literal: true

require 'rails_helper'

describe VirtualAgentSendUserInfoJob, type: :job do

  describe '#perform' do

    before(:each) do 
      Timecop.freeze(Time.local(2022, 9, 1))
      FactoryBot.create(:virtual_agent_user_access_record,first_name: 'Rob')
      FactoryBot.create(:virtual_agent_user_access_record, id: '2', first_name: 'Tracy', created_at: '2022-08-01 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record, id: '3', first_name: 'Betty', created_at: '2022-04-20 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record, id: '4', first_name: 'Walter', created_at: '2022-08-15 20:08:42.300961')

    end 

    it 'filters records by the target month and returns request object' do
      expected_csv_as_string = "id,action_type,first_name,last_name,ssn,icn,created_at,updated_at\n1,action_type,Rob,last_name,ssn,icn,2022-08-12 20:08:42 UTC,2022-09-12 20:08:42 UTC\n2,action_type,Tracy,last_name,ssn,icn,2022-08-01 20:08:42 UTC,2022-09-12 20:08:42 UTC\n4,action_type,Walter,last_name,ssn,icn,2022-08-15 20:08:42 UTC,2022-09-12 20:08:42 UTC\n"
      
      expected_request_object = { 'filename': 'chatbot-claims-appeals-Aug-2022.csv', 'payload': expected_csv_as_string }
      
      expect(VirtualAgentSendUserInfoJob.new.perform).to eq(expected_request_object)
    end

    it 'handles edge case for first month of the year and returns request object' do
      Timecop.freeze(Time.local(2022, 01, 1))
      FactoryBot.create(:virtual_agent_user_access_record, id: '5', first_name: 'John', created_at: '2021-12-07 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record, id: '6', first_name: 'Lennon', created_at: '2022-02-20 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record, id: '7', first_name: 'Paul', created_at: '2021-12-15 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record, id: '8', first_name: 'McCartney', created_at: '2021-12-20 20:08:42.300961')


      expected_csv_as_string = "id,action_type,first_name,last_name,ssn,icn,created_at,updated_at\n5,action_type,John,last_name,ssn,icn,2021-12-07 20:08:42 UTC,2022-09-12 20:08:42 UTC\n7,action_type,Paul,last_name,ssn,icn,2021-12-15 20:08:42 UTC,2022-09-12 20:08:42 UTC\n8,action_type,McCartney,last_name,ssn,icn,2021-12-20 20:08:42 UTC,2022-09-12 20:08:42 UTC\n"
      
      expected_request_object = { 'filename': 'chatbot-claims-appeals-Dec-2021.csv', 'payload': expected_csv_as_string }
      
      expect(VirtualAgentSendUserInfoJob.new.perform).to eq(expected_request_object)
    end

  end

  # TODO: address edge case with January - 1
  
end
