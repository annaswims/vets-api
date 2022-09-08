require 'json'

module V0
  module VirtualAgent
    class VirtualAgentControllerUtil

      def self.log_user_action(current_user, action_type, meta)

        log_data = current_user.dup.slice(
            '@icn',
            '@ssan',
            '@first_name',
            '@last_name',
            '@last_signed_in'
            )

        action = Object.new
        action[:action_type] = action_type
        action[:action_time] = Time.now
        action[:action_meta] = meta

        log_data[:virtual_agent_action] = action

        # TODO: replace with logic to write to Postgres ...
        puts log_data.to_json

      end

    end
  end
end