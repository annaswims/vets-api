# frozen_string_literal: true

class VirtualAgentSendClaimsUserInfoJob
  include Sidekiq::Worker

  def perform()

    claims_records = VirtualAgentUserAccessRecord.where(:action_type => 'claims')

    csv_string = CSV.generate do |csv|
      csv << ['id', 'action_type', 'first_name', 'last_name', 'ssn', 'icn', 'datetime']
      claims_records.to_a.each do |user_record|
        csv << user_record.attributes.values[0..6]
      end
    end

    current_datetime = Time.now
    month = Date::ABBR_MONTHNAMES[current_datetime.month]
    filename = "chatbot-claims-#{month}-#{current_datetime.day}-#{current_datetime.year}.csv"
    request_object = { 'filename': filename, 'payload': csv_string}

    response = sendReport(request_object)
    claims_records.destroy_all   
    response
  end

  def sendReport(request_object)
    uri = URI('https://prod-18.usgovtexas.logic.azure.us:443/workflows/474b982d9d204a7aab2cf587e52dbac5/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=bBRX8Cp6SIGXph4CjQeuuXnO6h3_7E9r7VWfZGWrvnA')
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req.body = request_object.to_json
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end
  end

end