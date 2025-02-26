# frozen_string_literal: true

require 'rails_helper'

describe VAOS::MessageForm, type: :model do
  let(:user) { build(:user, :vaos) }
  let(:request_id) { 'fake_request_id' }

  describe 'invalid object' do
    subject { described_class.new(user, request_id) }

    it 'validates presence of required attributes' do
      expect(subject).not_to be_valid
      expect(subject.errors.attribute_names).to contain_exactly(:message_text)
    end

    it 'raises a Common::Exceptions::ValidationErrors when trying to fetch coerced params' do
      expect { subject.params }.to raise_error(Common::Exceptions::ValidationErrors)
    end
  end

  describe 'valid object' do
    subject do
      described_class.new(user, request_id, message_text: 'I want to see doctor Jeckyl please.')
    end

    it 'validates presence of required attributes' do
      expect(subject).to be_valid
      expect(subject.sender_id).to eql(user.icn)
    end
  end
end
