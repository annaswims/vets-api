# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignIn::AccessToken, type: :model do
  let(:access_token) do
    create(:access_token,
           session_handle: session_handle,
           client_id: client_id,
           user_uuid: user_uuid,
           refresh_token_hash: refresh_token_hash,
           parent_refresh_token_hash: parent_refresh_token_hash,
           anti_csrf_token: anti_csrf_token,
           last_regeneration_time: last_regeneration_time,
           expiration_time: expiration_time,
           version: version,
           created_time: created_time)
  end

  let(:session_handle) { create(:oauth_session).handle }
  let(:user_uuid) { create(:user_account).id }
  let(:client_id) { SignIn::Constants::ClientConfig::CLIENT_IDS.first }
  let(:refresh_token_hash) { SecureRandom.hex }
  let(:parent_refresh_token_hash) { SecureRandom.hex }
  let(:anti_csrf_token) { SecureRandom.hex }
  let(:last_regeneration_time) { Time.zone.now }
  let(:version) { SignIn::Constants::AccessToken::CURRENT_VERSION }
  let(:expiration_time) { Time.zone.now + SignIn::Constants::AccessToken::VALIDITY_LENGTH_SHORT_MINUTES.minutes }
  let(:created_time) { Time.zone.now }

  describe 'validations' do
    describe '#session_handle' do
      subject { access_token.session_handle }

      context 'when session_handle is nil' do
        let(:session_handle) { nil }
        let(:expected_error_message) { "Validation failed: Session handle can't be blank" }
        let(:expected_error) { ActiveModel::ValidationError }

        it 'raises validation error' do
          expect { subject }.to raise_error(expected_error, expected_error_message)
        end
      end
    end

    describe '#client_id' do
      subject { access_token.client_id }

      context 'when client_id is nil' do
        let(:client_id) { nil }
        let(:expected_error_message) { "Validation failed: Client can't be blank, Client is not included in the list" }
        let(:expected_error) { ActiveModel::ValidationError }

        it 'raises validation error' do
          expect { subject }.to raise_error(expected_error, expected_error_message)
        end
      end

      context 'when client_id is arbitrary' do
        let(:client_id) { 'some-arbitrary-client-id' }
        let(:expected_error_message) { 'Validation failed: Client is not included in the list' }
        let(:expected_error) { ActiveModel::ValidationError }

        it 'raises validation error' do
          expect { subject }.to raise_error(expected_error, expected_error_message)
        end
      end
    end

    describe '#user_uuid' do
      subject { access_token.user_uuid }

      context 'when user_uuid is nil' do
        let(:user_uuid) { nil }
        let(:expected_error_message) { "Validation failed: User uuid can't be blank" }
        let(:expected_error) { ActiveModel::ValidationError }

        it 'raises validation error' do
          expect { subject }.to raise_error(expected_error, expected_error_message)
        end
      end
    end

    describe '#refresh_token_hash' do
      subject { access_token.refresh_token_hash }

      context 'when refresh_token_hash is nil' do
        let(:refresh_token_hash) { nil }
        let(:expected_error_message) { "Validation failed: Refresh token hash can't be blank" }
        let(:expected_error) { ActiveModel::ValidationError }

        it 'raises validation error' do
          expect { subject }.to raise_error(expected_error, expected_error_message)
        end
      end
    end

    describe '#anti_csrf_token' do
      subject { access_token.anti_csrf_token }

      context 'when anti_csrf_token is nil' do
        let(:anti_csrf_token) { nil }
        let(:expected_error_message) { "Validation failed: Anti csrf token can't be blank" }
        let(:expected_error) { ActiveModel::ValidationError }

        it 'raises validation error' do
          expect { subject }.to raise_error(expected_error, expected_error_message)
        end
      end
    end

    describe '#last_regeneration_time' do
      subject { access_token.last_regeneration_time }

      context 'when last_regeneration_time is nil' do
        let(:last_regeneration_time) { nil }
        let(:expected_error_message) { "Validation failed: Last regeneration time can't be blank" }
        let(:expected_error) { ActiveModel::ValidationError }

        it 'raises validation error' do
          expect { subject }.to raise_error(expected_error, expected_error_message)
        end
      end
    end

    describe '#version' do
      subject { access_token.version }

      context 'when version is arbitrary' do
        let(:version) { 'some-arbitrary-version' }
        let(:expected_error_message) { 'Validation failed: Version is not included in the list' }
        let(:expected_error) { ActiveModel::ValidationError }

        it 'raises validation error' do
          expect { subject }.to raise_error(expected_error, expected_error_message)
        end
      end

      context 'when version is nil' do
        let(:version) { nil }
        let(:expected_version) { SignIn::Constants::AccessToken::CURRENT_VERSION }

        it 'sets version to CURRENT_VERSION' do
          expect(subject).to be expected_version
        end
      end
    end

    describe '#expiration_time' do
      subject { access_token.expiration_time }

      before { Timecop.freeze }

      after { Timecop.return }

      context 'when expiration_time is nil' do
        let(:expiration_time) { nil }
        let(:expected_expiration_time) { Time.zone.now + validity_length }

        context 'and client_id is in a short token expiration defined config' do
          let(:client_id) { SignIn::Constants::ClientConfig::SHORT_TOKEN_EXPIRATION.first }
          let(:validity_length) { SignIn::Constants::AccessToken::VALIDITY_LENGTH_SHORT_MINUTES.minutes }

          it 'sets expired time to VALIDITY_LENGTH_SHORT_MINUTES from now' do
            expect(subject).to eq(expected_expiration_time)
          end
        end

        context 'and client_id is in a long token expiration defined config' do
          let(:client_id) { SignIn::Constants::ClientConfig::LONG_TOKEN_EXPIRATION.first }
          let(:validity_length) { SignIn::Constants::AccessToken::VALIDITY_LENGTH_LONG_MINUTES.minutes }

          it 'sets expired time to VALIDITY_LENGTH_LONG_MINUTES from now' do
            expect(subject).to eq(expected_expiration_time)
          end
        end
      end
    end

    describe '#created_time' do
      subject { access_token.created_time }

      before { Timecop.freeze }

      after { Timecop.return }

      context 'when created_time is nil' do
        let(:created_time) { nil }
        let(:expected_created_time) { Time.zone.now }

        it 'sets expired time to now' do
          expect(subject).to eq(expected_created_time)
        end
      end
    end
  end
end
