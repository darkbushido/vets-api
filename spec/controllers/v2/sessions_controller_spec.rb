# frozen_string_literal: true

require 'rails_helper'
require 'support/saml/form_validation_helpers'

RSpec.describe V2::SessionsController, type: :controller do
  include SAML::ValidationHelpers

  context 'when not logged in' do
    describe 'GET new' do
      context 'routes not requiring auth' do
        %w[logingov].each do |type|
          context "routes /sessions/#{type}/new to SessionsController#new with type: #{type}" do
            let(:url) do
              case type
              when 'idme'
              when 'logingov'
                'https://idp.int.identitysandbox.gov/openid_connect/authorize'
              end
            end
            it 'presents login form' do
              expect(get(:new, params: { type: type }))
                .to have_http_status(:ok)
              expect_oauth_post_form(response.body, "#{type}-form", url)     
              end
          end
        end
      end
    end

    describe 'POST callback' do
      context 'successful authentication' do
        it 'redirects user to home page' do
          VCR.use_cassette('identity/logingov_200_responses') do
            expect(post(:callback, params: { code: '6805c923-9f37-4b47-a5c9-214391ddffd5' }))
              .to redirect_to('http://localhost:3001/auth/login/callback?type=logingov')
          end
        end
      end

      context 'unsuccessful authentication' do
        it 'redirects to an auth failure page' do
          VCR.use_cassette('identity/logingov_400_responses') do
            expect(controller).to receive(:log_message_to_sentry)
            .with(
              'the server responded with status 400',
              :error
            )
            expect(post(:callback, params: { code: '6805c923-9f37-4b47-a5c9-214391ddffd5' }))
              .to redirect_to('http://localhost:3001/auth/login/callback?auth=fail&code=007')
            expect(response).to have_http_status(:found)
          end
        end
      end
    end
  end
end
