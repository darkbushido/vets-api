# frozen_string_literal: true

require 'rails_helper'
require 'support/controller_spec_helper'

RSpec.describe InheritedProofingController, type: :controller do
  let(:loa3_user) { create(:user) }

  describe 'GET auth' do
    subject { get(:auth) }

    context 'when user is not authenticated' do
      it 'returns a 401' do
        expect(subject.code).to eq('401')
      end
    end

    context 'authenticated user' do
      before { sign_in_as(loa3_user) }

      it '???' do
        VCR.use_cassette('inherited_proofing/mhv_200') do

        end
      end
    end
  end    
end
