# frozen_string_literal: true

require 'sidekiq'

module AppealsApi
  class AddIcnUpdater
    include Sidekiq::Worker

    def perform(appeal_id, appeal_class_str)
      appeal_class = Object.const_get(appeal_class_str)
      appeal = appeal_class.find(appeal_id)

      if appeal.form_data.nil? && appeal.auth_headers.nil?
        Rails.logger.error "#{appeal_class_str} missing PII, can't retrieve ICN. Appeal ID:#{appeal_id}."
      else
        add_icn_to_appeal(appeal)
      end
    end

    private

    def add_icn_to_appeal(appeal)
      unless appeal.instance_of?(::AppealsApi::NoticeOfDisagreement)
        appeal.update!(veteran_icn: target_veteran(appeal).mpi_icn)
      end

      # Happy path MPI lookup in vets-api is SSN. NOD doesn't have that, so
      # we have to utilize address attributes instead
      appeal.update!(veteran_icn: target_veteran_with_address(appeal)&.profile&.icn)
    end

    def target_veteran(appeal)
      veteran ||= Appellant.new(
        type: :veteran,
        auth_headers: appeal.auth_headers,
        form_data: appeal.form_data&.dig('data', 'attributes', 'veteran')
      )

      mpi_veteran ||= AppealsApi::Veteran.new(
        ssn: veteran.ssn,
        first_name: veteran.first_name,
        last_name: veteran.last_name,
        birth_date: veteran.birth_date.iso8601
      )

      mpi_veteran
    end

    def target_veteran_with_address(appeal)
      veteran ||= Appellant.new(
        type: :veteran,
        auth_headers: appeal.auth_headers,
        form_data: appeal.form_data&.dig('data', 'attributes', 'veteran')
      )

      veteran.define_singleton_method(:birth_date) do
        appeal.auth_headers['X-VA-Birth-Date']
      end
      veteran.define_singleton_method(:valid?) do
        true
      end
      veteran.define_singleton_method(:authn_context) do
        'authn'
      end
      veteran.define_singleton_method(:uuid) do
        nil
      end
      # AppealsApi::Veteran is wrapper for ClaimsApi::Veteran, which requires ssn.
      # Instead of modifying ClaimsApi::Veteran, we'll just query MPI directly.
      MPI::Service.new.find_profile(veteran)
    end
  end
end
