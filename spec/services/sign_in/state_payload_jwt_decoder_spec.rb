# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignIn::StatePayloadJwtDecoder do
  describe '#perform' do
    subject do
      SignIn::StatePayloadJwtDecoder.new(state_payload_jwt: state_payload_jwt).perform
    end

    let(:state_payload_jwt) do
      SignIn::StatePayloadJwtEncoder.new(acr: acr,
                                         client_id: client_id,
                                         code_challenge_method: code_challenge_method,
                                         type: type,
                                         code_challenge: code_challenge,
                                         client_state: client_state).perform
    end
    let(:code_challenge) { Base64.urlsafe_encode64('some-safe-code-challenge') }
    let(:code_challenge_method) { SignIn::Constants::Auth::CODE_CHALLENGE_METHOD }
    let(:client_state) { SecureRandom.alphanumeric(client_state_minimum_length + 1) }
    let(:acr) { SignIn::Constants::Auth::ACR_VALUES.first }
    let(:type) { SignIn::Constants::Auth::CSP_TYPES.first }
    let(:client_id) { SignIn::Constants::ClientConfig::CLIENT_IDS.first }
    let(:client_state_minimum_length) { SignIn::Constants::Auth::CLIENT_STATE_MINIMUM_LENGTH }

    context 'when state payload jwt is encoded with a different signature than expected' do
      let(:state_payload_jwt) do
        JWT.encode(
          jwt_payload,
          OpenSSL::PKey::RSA.new(2048),
          SignIn::Constants::Auth::JWT_ENCODE_ALGORITHM
        )
      end

      let(:jwt_payload) do
        {
          code_challenge: code_challenge,
          client_state: client_state,
          acr: acr,
          type: type,
          client_id: client_id
        }
      end
      let(:expected_error) { SignIn::Errors::StatePayloadSignatureMismatchError }
      let(:expected_error_message) { 'State JWT body does not match signature' }

      it 'returns a JWT signature mismatch error' do
        expect { subject }.to raise_error(expected_error, expected_error_message)
      end
    end

    context 'when state payload jwt is malformed' do
      let(:state_payload_jwt) { 'some-messed-up-jwt' }
      let(:expected_error) { SignIn::Errors::StatePayloadMalformedJWTError }
      let(:expected_error_message) { 'State JWT is malformed' }

      it 'raises a malformed jwt error' do
        expect { subject }.to raise_error(expected_error, expected_error_message)
      end
    end

    context 'when state payload jwt is valid' do
      it 'returns a State Payload with expected attributes' do
        decoded_state_payload = subject
        expect(decoded_state_payload.code_challenge).to eq(code_challenge)
        expect(decoded_state_payload.client_state).to eq(client_state)
        expect(decoded_state_payload.acr).to eq(acr)
        expect(decoded_state_payload.type).to eq(type)
        expect(decoded_state_payload.client_id).to eq(client_id)
      end
    end
  end
end
