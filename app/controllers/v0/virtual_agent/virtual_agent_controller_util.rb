require 'json'

module V0
  module VirtualAgent
    class VirtualAgentControllerUtil
      include Sidekiq::Worker

      def log_user_action(current_user, action_type, meta)

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
  end
end