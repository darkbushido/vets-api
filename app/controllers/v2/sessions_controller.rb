# frozen_string_literal: true

require 'login/after_login_actions'
require 'auth_logingov/service'

module V2
  class SessionsController < ApplicationController
    skip_before_action :verify_authenticity_token

    NO_AUTH_ACTIONS = %w[new].freeze
    REDIRECT_URLS = %w[idme logingov].freeze

    def new
      render_login
    end

    def callback
      binding.pry
      token = logingov_auth_service.token(params[:code])
      puts token
      # userInfo = AuthenticateService.new.userInfoFromToken(token)
      # user_login(userInfo)
    end

    private

    def render_login
      render body: logingov_auth_service.render_auth, content_type: 'text/html'
    end

    def logingov_auth_service
      AuthLogingov::Service.new
    end

    def authenticate
      return unless NO_AUTH_ACTIONS.include?(action_name)

      reset_session
    end

    def user_login(saml_response)

    end

    def user_logout(saml_response)

    end
  end
end
