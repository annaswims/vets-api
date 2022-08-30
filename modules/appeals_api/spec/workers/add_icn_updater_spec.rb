# frozen_string_literal: true

require 'rails_helper'

module AppealsApi
  RSpec.describe AddIcnUpdater, type: :job do
    let(:notice_of_disagreement) { create(:notice_of_disagreement_v2) }

    describe 'Notice Of Disagreement Submission' do
      context 'when all required address data is provided' do
        it 'succeeds' do
          VCR.use_cassette('mpi/find_candidate/valid_no_gender') do
            notice_of_disagreement.auth_headers.delete('X-Consumer-ID')
            notice_of_disagreement.save!

            expect(notice_of_disagreement.veteran_icn).to be(nil)
            described_class.new.perform(notice_of_disagreement.id, 'AppealsApi::NoticeOfDisagreement')
            expect(notice_of_disagreement.reload.veteran_icn).not_to be(nil)
          end
        end
      end

      context 'when required address keys are missing' do
        it 'raises an ArgumentError' do
          VCR.use_cassette('mpi/find_candidate/valid_no_gender') do
            notice_of_disagreement.form_data['data']['attributes']['veteran']['address'].delete('addressLine1')
            notice_of_disagreement.save!

            expect do
              described_class.new.perform(notice_of_disagreement.id, 'AppealsApi::NoticeOfDisagreement')
            end.to raise_error(ArgumentError, 'required keys are missing: [:addressLine1]')
          end
        end
      end

      context 'when required address keys are blank' do
        it 'raises an ArgumentError' do
          VCR.use_cassette('mpi/find_candidate/valid_no_gender') do
            notice_of_disagreement.form_data['data']['attributes']['veteran']['address']['addressLine1'] = ''
            notice_of_disagreement.save!

            expect do
              described_class.new.perform(notice_of_disagreement.id, 'AppealsApi::NoticeOfDisagreement')
            end.to raise_error(ArgumentError, 'required values are missing for keys: [:addressLine1]')
          end
        end
      end
    end
  end
end
