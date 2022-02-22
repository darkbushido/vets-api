# frozen_string_literal: true

require 'uri'
require 'auth_logingov/configuration'

module AuthLogingov
  class Service < Common::Client::Base
    configuration AuthLogingov::Configuration

    CLIENT_ID = Settings.logingov.client_id
    ACR_VALUES = IAL::LOGIN_GOV_IAL2
    TOKEN_TYPE_HINT = 'access_token'
    AUTH_PATH = 'openid_connect/authorize'
    RESPONSE_TYPE = 'code'
    PROMPT = 'select_account'
    SCOPE = 'profile email openid social_security_number'
    REDIRECT_URI = Settings.logingov.redirect_uri
    GRANT_TYPE = 'authorization_code'
    LOGINGOV_CLIENT_ASSERTION_TYPE = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'

    def render_auth
      renderer = ActionController::Base.renderer
      renderer.controller.prepend_view_path(Rails.root.join('lib', 'auth_logingov', 'templates'))
      renderer.render(template: 'logingov_get_form',
                      locals: {
                        url: auth_url,
                        params:
                        {
                          acr_values: ACR_VALUES,
                          client_id: CLIENT_ID,
                          nonce: SecureRandom.hex,
                          prompt: PROMPT,
                          redirect_uri: REDIRECT_URI,
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

    private

    def auth_url
      "#{Settings.logingov.oauth_url}/#{AUTH_PATH}"
    end

    def token_url
      "#{Settings.logingov.oauth_url}/api/openid_connect/token"
    end

    def token_params(code)
      {
        grant_type: GRANT_TYPE,
        code: code,
        client_assertion_type: LOGINGOV_CLIENT_ASSERTION_TYPE,
        client_assertion: client_assertion_jwt
      }.to_json
    end

    def client_assertion_jwt
      jwt_payload = {
        iss: CLIENT_ID,
        sub: CLIENT_ID,
        aud: token_url,
        jti: SecureRandom.hex,
        nonce: SecureRandom.hex,
        exp: Time.now.to_i + 1000
      }
      JWT.encode(jwt_payload, private_key, 'RS256')
    end

    def private_key
      OpenSSL::PKey::RSA.new(File.open(Settings.logingov.client_key_path))
    end

    # TODO: Put stuff in state
    def state
      SecureRandom.hex
    end
  end
end
