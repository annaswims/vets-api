FactoryBot.define do
  factory :virtual_agent_user_access_record, class: 'VirtualAgentUserAccessRecord' do
    id { "1" }
    action_type { "action_type" }
    first_name { "first_name" }
    last_name { "last_name" }
    ssn { "ssn" }
    icn { "icn" }
    created_at { '2022-08-12 20:08:42.300961' }
    updated_at { '2022-09-12 20:08:42.300961' }
  end
end
