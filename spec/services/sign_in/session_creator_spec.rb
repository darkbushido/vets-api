# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignIn::SessionCreator do
  let(:session_creator) { SignIn::SessionCreator.new(user_account: user_account) }

  describe '#perform' do
    subject { session_creator.perform }

    context 'when input object is a UserAccount' do
      let(:user_account) { create(:user_account) }

      context 'expected anti_csrf_token' do
        let(:expected_anti_csrf_token) { 'some-anti-csrf-token' }

        before do
          allow(SecureRandom).to receive(:hex).and_return(expected_anti_csrf_token)
        end

        it 'returns a Session Container with expected anti_csrf_token' do
          expect(subject.anti_csrf_token).to be(expected_anti_csrf_token)
        end
      end

      context 'expected session' do
        let(:expected_handle) { SecureRandom.uuid }
        let(:expected_created_time) { Time.zone.now }
        let(:expected_user_uuid) { user_account.id }
        let(:expected_expiration_time) do
          Time.zone.now + SignIn::Constants::RefreshToken::VALIDITY_LENGTH_MINUTES.minutes
        end
        let(:expected_double_hashed_parent_refresh_token) do
          Digest::SHA256.hexdigest(parent_refresh_token_hash)
        end
        let(:stubbed_random_number) { 'some-stubbed-random-number' }
        let(:parent_refresh_token_hash) { Digest::SHA256.hexdigest(parent_refresh_token.to_json) }
        let(:refresh_token) do
          create(:refresh_token,
                 user_uuid: expected_user_uuid,
                 parent_refresh_token_hash: parent_refresh_token_hash,
                 session_handle: expected_handle,
                 nonce: stubbed_random_number,
                 anti_csrf_token: stubbed_random_number)
        end
        let(:parent_refresh_token) do
          create(:refresh_token,
                 user_uuid: expected_user_uuid,
                 parent_refresh_token_hash: nil,
                 session_handle: expected_handle,
                 nonce: stubbed_random_number,
                 anti_csrf_token: stubbed_random_number)
        end

        before do
          allow(SecureRandom).to receive(:hex).and_return(stubbed_random_number)
          allow(SecureRandom).to receive(:uuid).and_return(expected_handle)
          allow(Time.zone).to receive(:now).and_return(expected_created_time)
        end

        it 'returns a Session Container with expected OAuth Session and fields' do
          session = subject.session
          expect(session.handle).to eq(expected_handle)
          expect(session.hashed_refresh_token).to eq(expected_double_hashed_parent_refresh_token)
          expect(session.refresh_creation).to eq(expected_created_time)
          expect(session.refresh_expiration).to eq(expected_expiration_time)
        end
      end

      context 'expected refresh_token' do
        let(:expected_handle) { SecureRandom.uuid }
        let(:expected_user_uuid) { user_account.id }
        let(:expected_anti_csrf_token) { stubbed_random_number }
        let(:stubbed_random_number) { 'some-stubbed-random-number' }
        let(:expected_parent_refresh_token_hash) { Digest::SHA256.hexdigest(parent_refresh_token.to_json) }
        let(:refresh_token) do
          create(:refresh_token,
                 user_uuid: expected_user_uuid,
                 parent_refresh_token_hash: parent_refresh_token_hash,
                 session_handle: expected_handle,
                 nonce: stubbed_random_number,
                 anti_csrf_token: stubbed_random_number)
        end
        let(:parent_refresh_token) do
          create(:refresh_token,
                 user_uuid: expected_user_uuid,
                 parent_refresh_token_hash: nil,
                 session_handle: expected_handle,
                 nonce: stubbed_random_number,
                 anti_csrf_token: stubbed_random_number)
        end

        before do
          allow(SecureRandom).to receive(:hex).and_return(stubbed_random_number)
          allow(SecureRandom).to receive(:uuid).and_return(expected_handle)
        end

        it 'returns a Session Container with expected Refresh Token and fields' do
          refresh_token = subject.refresh_token
          expect(refresh_token.session_handle).to eq(expected_handle)
          expect(refresh_token.anti_csrf_token).to eq(expected_anti_csrf_token)
          expect(refresh_token.user_uuid).to eq(expected_user_uuid)
          expect(refresh_token.parent_refresh_token_hash).to eq(expected_parent_refresh_token_hash)
        end
      end

      context 'expected access_token' do
        let(:expected_handle) { SecureRandom.uuid }
        let(:expected_user_uuid) { user_account.id }
        let(:expected_anti_csrf_token) { stubbed_random_number }
        let(:stubbed_random_number) { 'some-stubbed-random-number' }
        let(:expected_refresh_token_hash) { Digest::SHA256.hexdigest(refresh_token.to_json) }
        let(:refresh_token) do
          create(:refresh_token,
                 user_uuid: expected_user_uuid,
                 parent_refresh_token_hash: expected_parent_refresh_token_hash,
                 session_handle: expected_handle,
                 nonce: stubbed_random_number,
                 anti_csrf_token: expected_anti_csrf_token)
        end
        let(:parent_refresh_token) do
          create(:refresh_token,
                 user_uuid: expected_user_uuid,
                 parent_refresh_token_hash: nil,
                 session_handle: expected_handle,
                 nonce: stubbed_random_number,
                 anti_csrf_token: expected_anti_csrf_token)
        end
        let(:expected_parent_refresh_token_hash) { Digest::SHA256.hexdigest(parent_refresh_token.to_json) }
        let(:expected_last_regeneration_time) { Time.zone.now }

        before do
          allow(SecureRandom).to receive(:hex).and_return(stubbed_random_number)
          allow(SecureRandom).to receive(:uuid).and_return(expected_handle)
          allow(Time.zone).to receive(:now).and_return(expected_last_regeneration_time)
        end

        it 'returns a Session Container with expected Access Token and fields' do
          access_token = subject.access_token
          expect(access_token.session_handle).to eq(expected_handle)
          expect(access_token.anti_csrf_token).to eq(expected_anti_csrf_token)
          expect(access_token.user_uuid).to eq(expected_user_uuid)
          expect(access_token.refresh_token_hash).to eq(expected_refresh_token_hash)
          expect(access_token.parent_refresh_token_hash).to eq(expected_parent_refresh_token_hash)
          expect(access_token.last_regeneration_time).to eq(expected_last_regeneration_time)
        end
      end
    end
  end
end
