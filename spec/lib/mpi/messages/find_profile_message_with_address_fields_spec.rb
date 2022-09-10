# frozen_string_literal: true

require 'spec_helper'
require 'mpi/messages/find_profile_message_with_address_fields'

describe MPI::Messages::FindProfileMessageWithAddressFields do
  describe '.valid?' do
    subject { described_class.new(profile) }

    let(:missing_keys) { %i[addressLine1 city zipCode5 countryCodeISO2] }

    before do
      subject.validate
    end

    context 'with missing keys and values' do
      let(:profile) { {} }

      its(:valid?) { is_expected.to be(false) }
      its(:missing_keys) { is_expected.to match_array(missing_keys) }
      its(:missing_values) { is_expected.to match_array(missing_keys) }
    end

    context 'with missing values' do
      let(:profile) { { addressLine1: nil, city: '', zipCode5: '', countryCodeISO2: nil } }

      its(:valid?) { is_expected.to be(false) }
      its(:missing_keys) { is_expected.to be_blank }
      its(:missing_values) { is_expected.to match_array(missing_keys) }
    end

    context 'with required attributes' do
      let(:profile) { { addressLine1: '123 Main Street', city: 'New York', zipCode5: '12345', countryCodeISO2: 'US' } }

      its(:valid?) { is_expected.to be(true) }
      its(:missing_keys) { is_expected.to be_blank }
      its(:missing_values) { is_expected.to be_blank }
    end
  end
end
