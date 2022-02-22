# frozen_string_literal: true

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
      token = logingov_auth_service.token(params[:code])
      user_info = logingov_auth_service.user_info(token)
      user_login(user_info)
      # userInfo = AuthenticateService.new.userInfoFromToken(token)
      # user_login(userInfo)
    end

    private

    def render_login
      render body: logingov_auth_service.render_auth, content_type: 'text/html'
    end

    def logingov_auth_service
      @logingov_auth_service ||= AuthLogingov::Service.new
    end

    def authenticate
      return unless NO_AUTH_ACTIONS.include?(action_name)

      reset_session
    end

    def user_login(user_info)

    end
  end
end
