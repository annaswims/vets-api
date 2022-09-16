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

    it 'sends report' do
      # load up table with records
      Timecop.freeze(Time.local(2022, 9, 15))
      FactoryBot.create(:virtual_agent_user_access_record_for_claims, id: '1', first_name: 'Rob', created_at: '2022-08-12 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record_for_claims, id: '2', first_name: 'Tracy', created_at: '2022-08-01 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record_for_claims, id: '3', first_name: 'Betty', created_at: '2022-08-20 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record_for_claims, id: '4', first_name: 'Walter', created_at: '2022-08-16 20:08:42.300961')
      FactoryBot.create(:virtual_agent_user_access_record_default, id: '5', first_name: 'Tina', created_at: '2022-08-16 20:08:42.300961')

      expected_csv_as_string = "id,action_type,first_name,last_name,ssn,icn,datetime\n1,claims,Rob,last_name,ssn,icn,2022-08-12 20:08:42 UTC\n2,claims,Tracy,last_name,ssn,icn,2022-08-01 20:08:42 UTC\n3,claims,Betty,last_name,ssn,icn,2022-08-20 20:08:42 UTC\n4,claims,Walter,last_name,ssn,icn,2022-08-16 20:08:42 UTC\n"

      mock_http_response = {'filename': 'chatbot-claims-Sep-15-2022.csv', 'payload': expected_csv_as_string}

      job = VirtualAgentSendClaimsUserInfoJob.new
      allow(job).to receive(:sendReport) {mock_http_response}

      actual_response = job.perform()

      expect(job).to have_received(:sendReport)
      expect(actual_response).to eq(mock_http_response)

    end

    it 'deletes claims records from the database after job is done' do
      claims_records = VirtualAgentUserAccessRecord.all
      allow(claims_records).to receive(:[]) {[VirtualAgentUserAccessRecord.new(), VirtualAgentUserAccessRecord.new()]}
      allow(VirtualAgentUserAccessRecord). to receive(:where) {claims_records}
      allow(claims_records).to receive(:destroy_all)

      VirtualAgentSendClaimsUserInfoJob.new.perform()
      expect(claims_records).to have_received(:destroy_all)
    end

    # it 'calls power automate' do

    #   VCR.use_cassette('virtual_agent_vba_power_automate', :record => :once) do
    #     expected_csv_as_string = "id,action_type,first_name,last_name,ssn,icn,datetime\n1,claims,Rob,last_name,ssn,icn,2022-08-12 20:08:42 UTC\n2,claims,Tracy,last_name,ssn,icn,2022-08-01 20:08:42 UTC\n3,claims,Betty,last_name,ssn,icn,2022-08-20 20:08:42 UTC\n4,claims,Walter,last_name,ssn,icn,2022-08-16 20:08:42 UTC\n"

    #     uri = URI('https://prod-18.usgovtexas.logic.azure.us:443/workflows/474b982d9d204a7aab2cf587e52dbac5/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=bBRX8Cp6SIGXph4CjQeuuXnO6h3_7E9r7VWfZGWrvnA')
    #     req = Net::HTTP::Post.new(uri)
    #     req['Content-Type'] = 'application/json'
    #     req.body = { 'filename': 'chatbot-claims-Sep-15-2022.csv', 'payload': expected_csv_as_string}.to_json
    #     Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    #       http.request(req)
    #     end
    #   end

    # end

  end
end
