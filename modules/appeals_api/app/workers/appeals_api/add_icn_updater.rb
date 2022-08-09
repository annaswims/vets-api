# frozen_string_literal: true

require 'sidekiq'

module AppealsApi
  class AddIcnUpdater
    include Sidekiq::Worker

    def perform(appeal_id, appeal_class_str)
      appeal_class = Object.const_get(appeal_class_str)
      appeal = appeal_class.find(appeal_id)
      appeal.update!(veteran_icn: target_veteran(appeal).mpi_icn)
    end

    private

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
  end
end
