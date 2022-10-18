# frozen_string_literal: true

require 'common/models/base'

# MessageSearch model
class MessageSearch < Common::Base
  # include RedisCaching
  # redis_config REDIS_CONFIG[:secure_messaging_store]

  attribute :exact_match, Boolean
  attribute :sender_name, String
  attribute :subject, String
  attribute :category, String
  attribute :recipient_name, String
  attribute :from_date, Common::UTCTime
  attribute :to_date, Common::UTCTime
  attribute :message_id, Integer
end
