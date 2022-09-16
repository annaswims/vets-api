# frozen_string_literal: true

require 'rails_helper'

describe VirtualAgentSendClaimsUserInfoJob, type: :job do

  describe '#perform' do

    before(:each) do 
    end 

    it 'retrieves claims records from the database' do
      claims_records = VirtualAgentUserAccessRecord.all
      allow(claims_records).to receive(:[]) {[VirtualAgentUserAccessRecord.new(), VirtualAgentUserAccessRecord.new()]}
      allow(VirtualAgentUserAccessRecord). to receive(:where) {claims_records}

      VirtualAgentSendClaimsUserInfoJob.new.perform()
      expect(VirtualAgentUserAccessRecord).to have_received(:where).with({:action_type=>"claims"})
    end

    it 'returns request object' do
      # load up table with records
      Timecop.freeze(Time.local(2022, 9, 15))
      FactoryBot.create(:virtual_agent_user_access_record_for_claims, id: '1', first_name: 'Rob', created_at: '2022-08-12 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record_for_claims, id: '2', first_name: 'Tracy', created_at: '2022-08-01 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record_for_claims, id: '3', first_name: 'Betty', created_at: '2022-08-20 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record_for_claims, id: '4', first_name: 'Walter', created_at: '2022-08-16 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record_default, id: '5', first_name: 'Tina', created_at: '2022-08-16 20:08:42.300961')

      expected_csv_as_string = "id,action_type,first_name,last_name,ssn,icn,datetime\n1,claims,Rob,last_name,ssn,icn,2022-08-12 20:08:42 UTC\n2,claims,Tracy,last_name,ssn,icn,2022-08-01 20:08:42 UTC\n3,claims,Betty,last_name,ssn,icn,2022-08-20 20:08:42 UTC\n4,claims,Walter,last_name,ssn,icn,2022-08-16 20:08:42 UTC\n"

      actual_request_object = VirtualAgentSendClaimsUserInfoJob.new.perform()
      expect(actual_request_object[:filename]).to eq('chatbot-claims-Sep-15-2022.csv')
      expect(actual_request_object[:payload]).to eq (expected_csv_as_string)
    end

    it 'deletes claims records from the database after job is done' do
      claims_records = VirtualAgentUserAccessRecord.all
      allow(claims_records).to receive(:[]) {[VirtualAgentUserAccessRecord.new(), VirtualAgentUserAccessRecord.new()]}
      allow(VirtualAgentUserAccessRecord). to receive(:where) {claims_records}
      allow(claims_records).to receive(:destroy_all)

      VirtualAgentSendClaimsUserInfoJob.new.perform()
      expect(claims_records).to have_received(:destroy_all)
    end

  end
end
