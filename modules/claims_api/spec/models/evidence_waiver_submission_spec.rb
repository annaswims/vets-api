# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClaimsApi::EvidenceWaiverSubmission, type: :model do
  describe 'requiring fields' do
    context "when 'auth_headers_ciphertext' is not provided" do
      xit 'fails validation' do
        ews = ClaimsApi::EvidenceWaiverSubmission.create!(form_data_ciphertext: 'gdhsadgfh', encrypted_kms_key: 'bgdhjs', cid: '21635')

        expect { ews.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when 'cid' is not provided" do
      xit 'fails validation' do
        ews = ClaimsApi::EvidenceWaiverSubmission.create!(auth_headers_ciphertext: 'cghdsjg', form_data_ciphertext: 'gdhsadgfh', encrypted_kms_key: 'bgdhjs')
        
        expect { ews.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when all required attributes are provided' do
      it 'saves the record' do
        ews = ClaimsApi::EvidenceWaiverSubmission.create!(auth_headers_ciphertext: 'cghdsjg', form_data_ciphertext: 'gdhsadgfh', encrypted_kms_key: 'bgdhjs', cid: '21635')

        expect { ews.save! }.not_to raise_error
      end
    end
  end
end