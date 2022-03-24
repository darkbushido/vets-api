# frozen_string_literal: true

require 'logingov_inherited_proofing/configuration'

module LogingovInheritedProofing
  class Service < Common::Client::Base
    configuration LogingovInheritedProofing::Configuration

    SCOPE = 'profile email openid social_security_number'

    def render_auth(auth_code: nil)
      renderer = ActionController::Base.renderer
      renderer.controller.prepend_view_path(Rails.root.join('lib', 'logingov_inherited_proofing', 'templates'))
      renderer.render(template: 'oauth_get_form',
                      locals: {
                        url: auth_url,
                        params:
                        {
                          acr_values: IAL::LOGIN_GOV_IAL2,
                          client_id: config.client_id,
                          nonce: nonce,
                          prompt: config.prompt,
                          redirect_uri: config.redirect_uri,
                          response_type: config.response_type,
                          scope: SCOPE,
                          state: SecureRandom.hex,
                          inherited_proofing_auth: auth_code
                        }
                      },
                      format: :html)
    end

    private

    def auth_url
      "#{config.base_path}/#{config.auth_path}"
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

    def nonce
      @nonce ||= SecureRandom.hex
    end
  end
end
