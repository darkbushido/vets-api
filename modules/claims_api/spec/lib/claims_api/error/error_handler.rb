# frozen_string_literal: true

require 'rails_helper'
require 'claims_api/special_issue_mappers/bgs'
require 'token_validation/v2/client'
require 'claims_api/error/error_handler'
# require 'spec_helper'

# describe ApplicationController, type: :controller do
#   let(:scopes) { %w[claim.write] }
#   controller do
#     def test_invalid_token
#       raise ::Common::Exceptions::TokenValidationError
#     end
#     skip_before_action :authenticate
#   end

#   before :each do
#     routes.draw do
#       get 'test_invalid_token' => 'anonymous#test_invalid_token'
#     end
#   end

#   it 'catches an invalid token' do
#     with_okta_user(scopes) do |auth_header|
#       p auth_header
#       request.headers.merge!(auth_header) # https://github.com/rspec/rspec-rails/issues/1655
#       p request.headers
#       # byebug
#       get :test_invalid_token
#       puts response.body
#       expect(response).to have_http_status(401)
#       parsed_body = JSON.parse(response.body)
#       expect(parsed_body['detail']).to eq('Invalid token.')
#     end
#   end
# end

describe ApplicationController, type: :request do
  let(:veteran_id) { '1013062086V794840' }
  let(:scopes) { %w[claim.write] }
  let(:get_poa_path) { "/services/benefits/v2/veterans/#{veteran_id}/power-of-attorney" }

  it 'catches an invalid token' do
    with_okta_user(scopes) do |auth_header|
      allow(JWT).to receive(:decode).and_raise(JWT::DecodeError)

      get get_poa_path, headers: auth_header

      parsed_body = JSON.parse(response.body)
      expect(parsed_body['errors'][0]['detail']).to eq('Invalid token.')
    end
  end

  it 'catches an expired token' do
    with_okta_user(scopes) do |auth_header|
      i = 0
      allow(JWT).to receive(:decode) do
        raise(JWT::ExpiredSignature) if i > 2

        i += 1
        okta_jwt(scopes)
      end

      get get_poa_path, headers: auth_header

      parsed_body = JSON.parse(response.body)
      expect(parsed_body['errors'][0]['detail']).to eq('Invalid token.')
    end
  end
end
