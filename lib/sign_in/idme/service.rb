# frozen_string_literal: true

require 'uri'
require 'sign_in/url_service'
require 'sign_in/idme/configuration'

module SignIn::Idme
  class Service < Common::Client::Base
    configuration SignIn::Idme::Configuration

    def render_auth
      renderer = ActionController::Base.renderer
      renderer.controller.prepend_view_path(Rails.root.join('lib', 'sign_in', 'idme', 'templates'))
      renderer.render(template: 'idme_get_form',
                      locals: {
                        url: auth_url,
                        params:
                        {
                          scope: LOA::IDME_LOA3,
                          client_id: config.client_id,
                          nonce: SecureRandom.hex,
                          redirect_uri: config.redirect_uri,
                          response_type: config.response_type
                        }
                      },
                      format: :html)
    end

    def login_redirect_url(auth: 'success', code: nil)
      url_service = SignIn::URLService.new
      query_params = {}
      if auth == 'success'
        query_params[:type] = 'idme'
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
        sign_in: { service_name: 'idme_direct' }
      }
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

    def add_query(url, params)
      if params.any?
        uri = URI.parse(url)
        uri.query = Rack::Utils.parse_nested_query(uri.query).merge(params).to_query
        uri.to_s
      else
        url
      end
    end

    def auth_url
      "#{config.base_path}/#{config.auth_path}"
    end

    def token_params(code)
      {
        grant_type: config.grant_type,
        code: code,
        client_id: config.client_id,
        client_secret: config.client_secret
      }.to_json
    end

    def nonce
      @nonce ||= SecureRandom.hex
    end
  end
end
