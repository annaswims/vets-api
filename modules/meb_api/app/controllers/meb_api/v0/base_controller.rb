# frozen_string_literal: true

require 'dgi/claimant/service'
require 'dgi/letters/service'
require 'dgi/status/service'
require 'dgi/eligibility/service'
require 'dgi/automation/service'
require 'dgi/submission/service'
require 'dgi/enrollment/service'

require 'dgi/forms/service/sponsor_service'
require 'dgi/forms/service/claimant_service'
require 'dgi/forms/service/submission_service'
require 'dgi/forms/service/letter_service'

module MebApi
  module V0
    class BaseController < ::ApplicationController
      protected

      def check_flipper
        routing_error unless Flipper.enabled?(:show_meb_mock_endpoints)
      end

      def check_toe_flipper
        routing_error unless Flipper.enabled?(:show_updated_toe_app)
      end

      private

      def claim_status_service
        MebApi::DGI::Status::Service.new(@current_user)
      end

      def claim_letters_service
        MebApi::DGI::Letters::Service.new(@current_user)
      end

      def claimant_service
        MebApi::DGI::Claimant::Service.new(@current_user)
      end

      def forms_claimant_service
        MebApi::DGI::Forms::Claimant::Service.new(@current_user)
      end

      def form_letter_service
        MebApi::DGI::Forms::Letters::Service.new(@current_user)
      end

      def forms_sponsor_service
        MebApi::DGI::Forms::Sponsor::Service.new(@current_user)
      end

      def forms_submission_service
        MebApi::DGI::Forms::Submission::Service.new(@current_user)
      end
    end
  end
end
