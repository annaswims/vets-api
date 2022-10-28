# frozen_string_literal: true

require 'ddtrace'

module V0
  class UsersController < ApplicationController
    def show
      Datadog::Tracing.trace('Users#Show Web') do
        pre_serialized_profile = Users::Profile.new(current_user, @session_object).pre_serialize

        render(
          json: pre_serialized_profile,
          status: pre_serialized_profile.status,
          serializer: UserSerializer,
          meta: { errors: pre_serialized_profile.errors }
        )
      end
    end
  end
end
