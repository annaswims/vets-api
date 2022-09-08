# frozen_string_literal: true

class VirtualAgentStoreClaimsCallJob
  include Sidekiq::Worker

  def perform(current_user, action_type, meta)
    log_data = current_user.dup.slice(
            '@icn',
            '@ssan',
            '@first_name',
            '@last_name'
            )

    log_data[:action_type] = action_type
    log_data[:action_time] = Time.now
    log_data[:action_meta] = meta

    # TODO: replace with logic to write to Postgres ...
    
  end
end