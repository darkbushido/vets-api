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

    context 'when the payment service raises a Savon::Error (or its children SOAPFault etc.)' do
      it 'returns a 502 with JSON API spec formatted error details' do
        sign_in_as(user)
        allow_any_instance_of(BGS::Services).to receive(:payment_information).and_raise(Savon::Error)

        get(:index)

        expect(response).to have_http_status(:bad_gateway)
        expect(response.parsed_body).to eq({
                                             'errors' => [
                                               {
                                                 'title' => 'Bad Gateway',
                                                 'detail' => 'Savon::Error',
                                                 'code' => 'BGS_PAYMENT_HISTORY_502',
                                                 'source' => 'BGS::PaymentService',
                                                 'status' => '502'
                                               }
                                             ]
                                           })
      end
    end

    context 'when the payment service raises a BGS::ShareError' do
      it 'returns a 502 with JSON API spec formatted error details' do
        sign_in_as(user)
        allow_any_instance_of(BGS::Services).to receive(:payment_information).and_raise(BGS::ShareError.new(
                                                                                          'bad news bears', 500
                                                                                        ))

        get(:index)

        expect(response).to have_http_status(:bad_gateway)
        expect(response.parsed_body).to eq({
                                             'errors' => [
                                               {
                                                 'title' => 'Bad Gateway',
                                                 'detail' => 'bad news bears',
                                                 'code' => 'BGS_PAYMENT_HISTORY_502',
                                                 'source' => 'BGS::PaymentService',
                                                 'status' => '502'
                                               }
                                             ]
                                           })
      end
    end

    context 'when an unexpected error occurs' do
      it 'returns a 500 with JSON API spec formatted error details' do
        sign_in_as(user)
        allow_any_instance_of(BGS::Services).to receive(:payment_information).and_raise(ArgumentError)

        get(:index)

        expect(response).to have_http_status(:internal_server_error)
        expect(response.parsed_body['errors'].first).to include(
          {
            'title' => 'Internal server error',
            'detail' => 'Internal server error',
            'code' => '500',
            'status' => '500'
          }
        )
      end
    end
  end
end
