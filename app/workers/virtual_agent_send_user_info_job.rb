# frozen_string_literal: true

class VirtualAgentSendUserInfoJob
  include Sidekiq::Worker

  def perform()
    current_datetime = Time.now
    month_int = current_datetime.month - 1
    year = current_datetime.year
    if month_int == 0
      month_int = 12
      year = current_datetime.year - 1
    end
    month = Date::ABBR_MONTHNAMES[month_int]

    csv_string = CSV.generate do |csv|
      csv << VirtualAgentUserAccessRecord.attribute_names
      VirtualAgentUserAccessRecord.find_by_sql("SELECT * FROM virtual_agent_user_access_records WHERE EXTRACT(month FROM created_at) = #{month_int}").to_a.each do |user_record|
        csv << user_record.attributes.values
      end
    end

    filename = "chatbot-claims-appeals-#{month}-#{year}.csv"

    request_object = { 'filename': filename, 'payload': csv_string}
    # puts request_object
    request_object
    
  end
end