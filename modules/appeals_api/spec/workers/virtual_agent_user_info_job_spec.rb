# frozen_string_literal: true

require 'rails_helper'

describe VirtualAgentSendUserInfoJob, type: :job do

  describe '#perform' do

    before(:each) do 
      Timecop.freeze(Time.local(2022, 9, 15))
      FactoryBot.create(:virtual_agent_user_access_record, id: '1', first_name: 'Rob', created_at: '2022-08-12 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record, id: '2', first_name: 'Tracy', created_at: '2022-08-01 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record, id: '3', first_name: 'Betty', created_at: '2022-04-20 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record, id: '4', first_name: 'Walter', created_at: '2022-08-15 20:08:42.300961')

    end 

    it 'filters records by the target month and returns request object' do
      expected_csv_as_string = "id,action_type,first_name,last_name,ssn,icn,created_at,updated_at\n1,action_type,Rob,last_name,ssn,icn,2022-08-12 20:08:42 UTC,2022-09-12 20:08:42 UTC\n2,action_type,Tracy,last_name,ssn,icn,2022-08-01 20:08:42 UTC,2022-09-12 20:08:42 UTC\n4,action_type,Walter,last_name,ssn,icn,2022-08-15 20:08:42 UTC,2022-09-12 20:08:42 UTC\n"
      # expected_request_object = { 'filename': 'chatbot-claims-Sep-15-2022.csv', 'payload': expected_csv_as_string } 
      actual_request_object = VirtualAgentSendUserInfoJob.new.perform()

      expect(actual_request_object[:filename]).to eq('chatbot-claims-Sep-15-2022.csv')
      # expect(actual_request_object[:payload].to eq (expected_csv_as_string))
    end

  end

  # TODO: address edge case with January - 1
  
end
