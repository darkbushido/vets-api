# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V0::Profile::PaymentHistoryController, type: :controller do
  let(:user) { create(:evss_user) }

  describe '#index' do
    context 'with only regular payments' do
      it 'returns only payments and no return payments' do
        VCR.use_cassette('bgs/payment_history/retrieve_payment_summary_with_bdn') do
          sign_in_as(user)
          get(:index)

          expect(response.code).to eq('200')
          expect(response).to have_http_status(:ok)

          expect(JSON.parse(response.body)['data']['attributes']['payments'].count).to eq(47)
          expect(JSON.parse(response.body)['data']['attributes']['return_payments'].count).to eq(0)
        end
      end
    end

    context 'with mixed payments and return payments' do
      it 'returns both' do
        VCR.use_cassette('bgs/payment_history/retrieve_payment_summary_with_bdn_returns') do
          sign_in_as(user)
          get(:index)

          expect(response.code).to eq('200')
          expect(response).to have_http_status(:ok)

          expect(JSON.parse(response.body)['data']['attributes']['payments'].count).to eq(2)
          expect(JSON.parse(response.body)['data']['attributes']['return_payments'].count).to eq(2)
        end
      end
    end

    context 'when BGS::Services returns a Savon::SOAPFault' do
      it 'returns a 502 and logs the original error' do
        sign_in_as(user)
        allow_any_instance_of(BGS::Services).to receive(:payment_information).and_raise(Savon::SOAPFault)

        get(:index)

        expect(response).to have_http_status(:bad_gateway)
        expect(response.parsed_body).to eq({
                                             'errors' => [
                                               {
                                                 'title' => 'Bad Gateway',
                                                 'detail' => 'Received an an invalid response from the upstream server.',
                                                 'code' => 'BGS_PAYMENT_HISTORY_502',
                                                 'source' => 'BGS::PaymentService',
                                                 'status' => '502'
                                               }
                                             ]
                                           })
      end
    end
  end
end
