# frozen_string_literal: true

class VirtualAgentSendClaimsUserInfoJob
  include Sidekiq::Worker

  def perform()
    current_datetime = Time.now
    month = Date::ABBR_MONTHNAMES[current_datetime.month]
    claims_records = VirtualAgentUserAccessRecord.where(:action_type => 'claims')

    csv_string = CSV.generate do |csv|
      csv << ['id', 'action_type', 'first_name', 'last_name', 'ssn', 'icn', 'datetime']
      claims_records.to_a.each do |user_record|
        csv << user_record.attributes.values[0..6]
      end
    end

    filename = "chatbot-claims-#{month}-#{current_datetime.day}-#{current_datetime.year}.csv"

    request_object = { 'filename': filename, 'payload': csv_string}

    claims_records.destroy_all

    request_object
    
  end
end