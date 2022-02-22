# frozen_string_literal: true

require 'uri'
require 'auth_logingov/configuration'

module AuthLogingov
  class Service < Common::Client::Base
    configuration AuthLogingov::Configuration

    AUTH_PATH = 'openid_connect/authorize'
    TOKEN_PATH = 'api/openid_connect/token'
    RESPONSE_TYPE = 'code'
    PROMPT = 'select_account'
    SCOPE = 'profile email openid social_security_number'
    GRANT_TYPE = 'authorization_code'
    CLIENT_ASSERTION_TYPE = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
    CLIENT_ASSERTION_EXPIRATION_SECONDS = 1000

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
                          prompt: PROMPT,
                          redirect_uri: config.redirect_uri,
                          response_type: RESPONSE_TYPE,
                          scope: SCOPE,
                          state: state
                        }
                      },
                      format: :html)
    end

    def token(code)
      response = perform(
        :post, 'api/openid_connect/token', token_params(code), { 'Content-Type' => 'application/json' }
      )
      response.body
    rescue Common::Client::Errors::ClientError => e
      raise e
    end

    def user_info(token)
      response = perform(:get, 'api/openid_connect/userinfo', nil, { 'Authorization' => "Bearer #{token}" })
      response.body
    rescue Common::Client::Errors::ClientError => e
      raise e
    end

    private

    def auth_url
      "#{config.base_path}/#{AUTH_PATH}"
    end

    def token_url
      "#{config.base_path}/#{TOKEN_PATH}"
    end

    def token_params(code)
      {
        grant_type: GRANT_TYPE,
        code: code,
        client_assertion_type: CLIENT_ASSERTION_TYPE,
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
        exp: Time.now.to_i + CLIENT_ASSERTION_EXPIRATION_SECONDS
      }
      JWT.encode(jwt_payload, private_key, 'RS256')
    end

    def private_key
      OpenSSL::PKey::RSA.new(File.open(config.client_key_path))
    end

    def state
      @state ||= SecureRandom.hex
    end

    def nonce
      @nonce ||= SecureRandom.hex
    end
  end
end
