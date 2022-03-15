# frozen_string_literal: true

require 'rails_helper'
require 'support/saml/form_validation_helpers'

RSpec.describe SignInController, type: :controller do
  include SAML::ValidationHelpers

  context 'when not logged in' do
    describe 'GET new' do
      context 'routes not requiring auth' do
        %w[logingov idme].each do |type|
          context "routes /sign_in/#{type}/new to SignInController#new with type: #{type}" do
            let(:url) do
              case type
              when 'logingov'
                'https://idp.int.identitysandbox.gov/openid_connect/authorize'
              when 'idme'
                'https://api.idmelabs.com/oauth/authorize'
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

    describe 'GET callback' do
      %w[logingov idme].each do |type|
        let(:code) do
          case type
          when 'logingov'
            '6805c923-9f37-4b47-a5c9-214391ddffd5'
          when 'idme'
            'b6bd8e0aff604043a29690dcbd40e33a'
          end
        end

        context 'successful authentication' do
          it 'redirects user to home page' do
            VCR.use_cassette("identity/#{type}_200_responses") do
              post(:callback, params: { type: type, code: code })
              expect(response).to redirect_to("http://localhost:3001/auth/login/callback?type=#{type}")
            end
          end
        end

        context 'unsuccessful authentication' do
          it 'redirects to an auth failure page' do
            VCR.use_cassette("identity/#{type}_400_responses") do
              expect(controller).to receive(:log_message_to_sentry)
                .with(
                  'the server responded with status 400',
                  :error
                )
              post(:callback, params: { type: type, code: code })
              expect(response).to redirect_to('http://localhost:3001/auth/login/callback?auth=fail&code=007')
              expect(response).to have_http_status(:found)
            end
          end
        end
      end
    end
  end
end
