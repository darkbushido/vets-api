# frozen_string_literal: true

require 'rails_helper'
require 'inherited_proofing/mhv/service'

describe InheritedProofing::MHV::Service do
  let(:user) { FactoryBot.create(:user, :loa3) }
  let(:service_obj) { described_class.new(user) }
  let(:correlation_id) { 19031408 } # rubocop:disable Style/NumericLiterals
  let(:correlation_id_response) do
    {
      'correlationId' => correlation_id,
      'accountStatus' => 'Premium',
      'apiCompletionStatus' => 'Successful'
    }
  end
  let(:correlation_id_error_response) do
    {
      'errorCode' => 99,
      'developerMessage' => '',
      'message' => 'Unknown application error occurred'
    }
  end

  describe 'correlation_id api' do
    context 'with existing correlation_id' do
      it 'will use existing user correlation_id if one exists' do
        expect(service_obj.send(:correlation_id)).to eq(user.mhv_correlation_id)
      end
    end

    context 'with no existing correlation_id' do
      before do
        allow_any_instance_of(User).to receive(:mhv_correlation_id).and_return(nil)
        allow_any_instance_of(described_class).to receive(:mhv_api_request).and_return(correlation_id_response)
      end

      it 'can sucessfully exchange ICN for correlation_id' do
        expect(service_obj.send(:correlation_id)).to eq(correlation_id)
      end
    end

    context 'when unable to find a user by ICN' do
      before do
        allow_any_instance_of(User).to receive(:mhv_correlation_id).and_return(nil)
        allow_any_instance_of(described_class).to receive(:mhv_api_request).and_return(correlation_id_error_response)
      end

      it 'will fail if user is not found' do
        expect(service_obj.send(:correlation_id)).to eq(nil)
        expect(service_obj.identity_proof_data).to eq({})
      end
    end

    context 'with application error' do
      before do
        allow_any_instance_of(User).to receive(:mhv_correlation_id).and_return(nil)
        allow_any_instance_of(described_class).to receive(:perform).and_raise(Common::Client::Errors::ClientError)
      end

      it 'will return false if mhv service is down' do
        expect(service_obj.send(:correlation_id)).to eq(nil)
        expect(service_obj.identity_proof_data).to eq({})
      end
    end
  end

  describe 'identity proofed data api' do
    context 'when user is found and eligible' do
      let(:identity_data_response) do
        {
          'mhvId' => 19031205, # rubocop:disable Style/NumericLiterals
          'identityProofedMethod' => 'IPA',
          'identityProofingDate' => '2020-12-14',
          'identityDocumentExist' => true,
          'identityDocumentInfo' => {
            'primaryIdentityDocumentNumber' => '73929233',
            'primaryIdentityDocumentType' => 'StateIssuedId',
            'primaryIdentityDocumentCountry' => 'United States',
            'primaryIdentityDocumentExpirationDate' => '2026-03-30'
          }
        }
      end

      before do
        allow_any_instance_of(described_class).to receive(:mhv_api_request).and_return(identity_data_response)
      end

      it 'will return hash if user has identity proof' do
        expect(service_obj.identity_proof_data).to eq(identity_data_response)
      end
    end

    context 'when user is found and not eligible' do
      let(:identity_data_failed_response) do
        {
          'mhvId' => 9712240, # rubocop:disable Style/NumericLiterals
          'identityDocumentExist' => false
        }
      end

      before do
        allow_any_instance_of(described_class).to receive(:mhv_api_request).and_return(identity_data_failed_response)
      end

      it 'will return empty hash if user does not have identity proof' do
        expect(service_obj.identity_proof_data).to eq(identity_data_failed_response)
      end
    end

    context 'with application error' do
      before do
        allow_any_instance_of(described_class).to receive(:perform).and_raise(Common::Client::Errors::ClientError)
      end

      it 'will return empty hash if mhv service is down' do
        expect(service_obj.identity_proof_data).to eq({})
      end
    end
  end
end
