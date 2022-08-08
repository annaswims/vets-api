# frozen_string_literal: true

require 'sidekiq'

module AppealsApi
  class AddIcnUpdater
    include Sidekiq::Worker

    def perform(submission)
      submission.update!(veteran_icn: target_veteran.mpi_icn)
    end

    private

    def target_veteran
      veteran ||= Appellant.new(
        type: :veteran,
        auth_headers: request_headers,
        form_data: submission.form_data&.dig('data', 'attributes', 'veteran')
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
