# frozen_string_literal: true

require 'rails_helper'

describe VirtualAgentSendUserInfoJob, type: :job do
  describe '#perform' do

    before(:each) do 
      user_record = VirtualAgentUserAccessRecord.create(action_type: 'action_type', first_name: 'first_name', last_name: 'last_name', ssn: 'ssn', icn: 'icn', created_at: '2022-08-01 20:08:42.300961')
      user_record.save
      # user_record_1 = FactoryBot.build(:virtual_agent_user_access_record, first_name: 'Rob')
      # user_record_2 = FactoryBot.build(:virtual_agent_user_access_record, first_name: 'Tracy', created_at: '2022-08-01 20:08:42.300961')
      # user_record_3 = FactoryBot.build(:virtual_agent_user_access_record, first_name: 'Betty', created_at: '2022-04-20 20:08:42.300961')
      # user_record_4 = FactoryBot.build(:virtual_agent_user_access_record, first_name: 'Walter', created_at: '2022-08-15 20:08:42.300961')
      # allow(VirtualAgentUserAccessRecord).to receive(:all) { [ user_record_1, user_record_2, user_record_3, user_record_4 ] }

      Timecop.freeze(Time.local(2022, 9, 1))
    end 

    it 'returns request object' do
      expect(VirtualAgentUserAccessRecord).to receive (:all)

      expected_csv_as_string = "id,action_type,first_name,last_name,ssn,icn,created_at,updated_at\n1,action_type,Rob,last_name,ssn,icn,2022-08-12 20:08:42 UTC,2022-09-12 20:08:42 UTC\n1,action_type,Tracy,last_name,ssn,icn,2022-08-01 20:08:42 UTC,2022-09-12 20:08:42 UTC\n1,action_type,Walter,last_name,ssn,icn,2022-08-15 20:08:42 UTC,2022-09-12 20:08:42 UTC\n"
      
      expected_request_object = { 'filename': 'chatbot-claims-appeals-Aug-2022.csv', 'payload': expected_csv_as_string }
      
      expect(VirtualAgentSendUserInfoJob.new.perform).to eq(expected_request_object)
    end
  end
  
end
