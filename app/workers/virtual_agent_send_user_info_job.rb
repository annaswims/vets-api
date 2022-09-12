# frozen_string_literal: true

class VirtualAgentSendUserInfoJob
  include Sidekiq::Worker

  def perform()
    all_records = VirtualAgentUserAccessRecord.all
    puts 'in job'
    puts all_records
    puts all_records.inspect
  end
end