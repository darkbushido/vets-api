# frozen_string_literal: true

require 'uri'
require 'auth_logingov/configuration'

module AuthLogingov
  class Service < Common::Client::Base
    configuration AuthLogingov::Configuration

    SCOPE = 'profile email openid social_security_number'

    def render_auth
      renderer = ActionController::Base.renderer
      renderer.controller.prepend_view_path(Rails.root.join('lib', 'auth_logingov', 'templates'))
      renderer.render(template: 'logingov_get_form',
                      locals: {
                        url: auth_url,
                        params:
                        {
                          acr_values: IAL::LOGIN_GOV_IAL2,
                          client_id: config.client_id,
                          nonce: SecureRandom.hex,
                          prompt: config.prompt,
                          redirect_uri: config.redirect_uri,
                          response_type: config.response_type,
                          scope: SCOPE,
                          state: state
                        }
                      },
                      format: :html)
    end

    def token(code)
      response = perform(
        :post, config.token_path, token_params(code), { 'Content-Type' => 'application/json' }
      )
      response.body
    rescue Common::Client::Errors::ClientError => e
      raise e
    end

    def user_info(token)
      response = perform(:get, config.userinfo_path, nil, { 'Authorization' => "Bearer #{token}" })
      response.body
    rescue Common::Client::Errors::ClientError => e
      raise e
    end

    private

    def auth_url
      "#{config.base_path}/#{config.auth_path}"
    end

    def token_url
      "#{config.base_path}/#{config.token_path}"
    end

    def token_params(code)
      {
        grant_type: config.grant_type,
        code: code,
        client_assertion_type: config.client_assertion_type,
        client_assertion: client_assertion_jwt
      }.to_json
    end

    def client_assertion_jwt
      jwt_payload = {
        iss: config.client_id,
        sub: config.client_id,
        aud: token_url,
        jti: SecureRandom.hex,
        nonce: nonce,
        exp: Time.now.to_i + config.client_assertion_expiration_seconds
      }
      JWT.encode(jwt_payload, config.ssl_key, 'RS256')
    end

    def state
      @state ||= SecureRandom.hex
    end

    def nonce
      @nonce ||= SecureRandom.hex
    end
  end
end
