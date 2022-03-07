# frozen_string_literal: true

require 'uri'
require 'sign_in/url_service'
require 'sign_in/logingov/configuration'
require 'sign_in/shared_service_behavior'

module SignIn::Logingov
  class Service < Common::Client::Base
    include SignIn::SharedServiceBehavior
    configuration SignIn::Logingov::Configuration

    SCOPE = 'profile email openid social_security_number'

    def render_auth
      renderer = ActionController::Base.renderer
      renderer.controller.prepend_view_path(Rails.root.join('lib', 'sign_in', 'logingov', 'templates'))
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

    def login_redirect_url(auth: 'success', code: nil)
      url_service = SignIn::URLService.new
      query_params = {}
      if auth == 'success'
        query_params[:type] = 'logingov'
      else
        query_params[:auth] = auth
        query_params[:code] = code if code
      end
      add_query("#{url_service.base_redirect_url}/auth/login/callback", query_params)
    end

    def normalized_attributes(user_info)
      loa = user_info[:verified_at].nil? ? LOA::ONE : LOA::THREE
      {
        uuid: user_info[:sub],
        loa: { current: loa, highest: loa },
        ssn: user_info[:social_security_number].tr('-', ''),
        birth_date: user_info[:birthdate],
        first_name: user_info[:given_name],
        last_name: user_info[:family_name],
        email: user_info[:email],
        sign_in: { service_name: 'logingov_direct' }
      }
    end
  end
end
