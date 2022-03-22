# frozen_string_literal: true

require 'rails_helper'
require 'inherited_proofing/mhv/service'

describe InheritedProofing::MHV::Service do
  let(:user) { FactoryBot.create(:user, :loa3) }

  context 'correlation_id api' do
    it 'will use existing user correlation_id if one exists' do
      described_class.new(user).verified?
    end
    it 'can sucessfully exchange ICN for correlation_id'
    it 'will fail if user is not found'
    it 'will fail if mhv service is down'
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
