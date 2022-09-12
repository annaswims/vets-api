# frozen_string_literal: true

class VirtualAgentStoreUserInfoJob
  include Sidekiq::Worker

  def perform(first_name,last_name,ssn,icn, action_type, meta)
    user_info = VirtualAgentUserAccessRecord.create(action_type: action_type, first_name: first_name, last_name: last_name, ssn: ssn, icn: icn)
    user_info.save
  end
end