# frozen_string_literal: true

require 'rails_helper'

module AppealsApi
  RSpec.describe AddIcnUpdater, type: :job do
    let(:notice_of_disagreement) { create(:notice_of_disagreement) }

    describe 'Notice Of Disagreement' do
      it 'queries MPI with address data instead' do
        VCR.use_cassette('mpi/find_candidate/valid_no_gender') do
          notice_of_disagreement.auth_headers.delete('X-VA-SSN')
          notice_of_disagreement.save!

          expect(notice_of_disagreement.veteran_icn).to be(nil)
          described_class.new.perform(notice_of_disagreement.id, 'AppealsApi::NoticeOfDisagreement')
          expect(notice_of_disagreement.reload.veteran_icn).not_to be(nil)
        end
      end
    end
  end
end
