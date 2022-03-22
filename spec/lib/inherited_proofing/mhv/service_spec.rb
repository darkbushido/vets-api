# frozen_string_literal: true

require 'rails_helper'
require 'inherited_proofing/mhv/service'

describe InheritedProofing::MHV::Service do
  let(:user) { FactoryBot.create(:user, :loa3) }
  let(:service_obj) { described_class.new(user) }
  let(:correlation_id) { 19031408 }
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
        expect(service_obj.verified?).to eq(false)
      end
    end

    context 'with application error' do
      before do
        allow_any_instance_of(User).to receive(:mhv_correlation_id).and_return(nil)
      end

      it 'will fail if mhv service is down' do
        expect(service_obj.send(:correlation_id)).to eq('whatever')
      end
    end
  end

  context 'identity proofed data api' do
    context 'when user is found' do
      it 'will return true if user has identity proofing'
      it 'will return false if user does not have identity proofing'
    end
    it 'will fail if user is not found'
    it 'will fail if mhv service is down'
  end
end
