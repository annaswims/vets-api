# frozen_string_literal: true

require 'rails_helper'

describe VirtualAgentSendClaimsUserInfoJob, type: :job do

  expected_csv_as_string = "id,action_type,first_name,last_name,ssn,icn,datetime\n1,claims,Rob,last_name,ssn,icn,2022-08-12 20:08:42 UTC\n2,claims,Tracy,last_name,ssn,icn,2022-08-01 20:08:42 UTC\n3,claims,Betty,last_name,ssn,icn,2022-08-20 20:08:42 UTC\n4,claims,Walter,last_name,ssn,icn,2022-08-16 20:08:42 UTC\n"
  mock_http_request_body = {'filename' => 'chatbot-claims-Sep-15-2022.csv', 'payload' => expected_csv_as_string}
  mock_http_response_success = { 'status' => 'success', 'request-body' => mock_http_request_body }

  describe '#perform' do

    before(:each) do 
      @job = VirtualAgentSendClaimsUserInfoJob.new
      allow(@job).to receive(:sendReport) {mock_http_response_success}
    end 

    it 'retrieves claims records from the database' do
      claims_records = VirtualAgentUserAccessRecord.all
      allow(claims_records).to receive(:[]) {[VirtualAgentUserAccessRecord.new(), VirtualAgentUserAccessRecord.new()]}
      allow(VirtualAgentUserAccessRecord).to receive(:where) {claims_records}

      @job.perform()
      expect(VirtualAgentUserAccessRecord).to have_received(:where).with({:action_type=>"claims"})
    end

    it 'generates request object and sends report' do
      # load up table with records
      Timecop.freeze(Time.local(2022, 9, 15))
      FactoryBot.create(:virtual_agent_user_access_record_for_claims, id: '1', first_name: 'Rob', created_at: '2022-08-12 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record_for_claims, id: '2', first_name: 'Tracy', created_at: '2022-08-01 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record_for_claims, id: '3', first_name: 'Betty', created_at: '2022-08-20 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record_for_claims, id: '4', first_name: 'Walter', created_at: '2022-08-16 20:08:42.300961')

      actual_response = @job.perform()

      expect(@job).to have_received(:sendReport)
      expect(actual_response).to eq(mock_http_response_success)

    end

    it 'deletes claims records from the database after job is done' do
      claims_records = VirtualAgentUserAccessRecord.all
      allow(claims_records).to receive(:[]) {[VirtualAgentUserAccessRecord.new(), VirtualAgentUserAccessRecord.new()]}
      allow(VirtualAgentUserAccessRecord). to receive(:where) {claims_records}
      allow(claims_records).to receive(:destroy_all)

      @job.perform()
      expect(claims_records).to have_received(:destroy_all)
    end

  end

  describe('#sendReport') do

    it 'POSTs to Power Automate URL' do
      VCR.use_cassette('virtual_agent_vba_power_automate', :record => :none, :match_requests_on => [:host]) do
        response = VirtualAgentSendClaimsUserInfoJob.new.sendReport(mock_http_request_body)
        response_as_json = JSON.parse(response.body)
        expect(response.code).to eq ('200')
        expect(response_as_json['status']).to eq ('success')
        expect(response_as_json['request-body']).to eq (mock_http_request_body)
      end
    end
    
  end

end
