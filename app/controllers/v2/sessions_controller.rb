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
      response = logingov_auth_service.token(params[:code])
      user_info = logingov_auth_service.user_info(response[:access_token])
      user_login(user_info)
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
      normalized_attributes = {
        uuid: user_info[:sub],
        loa: { current: LOA::THREE, highest: LOA::THREE },
        ssn: user_info[:social_security_number].tr('-', ''),
        birth_date: user_info[:birthdate],
        first_name: user_info[:given_name],
        last_name: user_info[:family_name],
        email: user_info[:email],
        sign_in: { service_name: 'logingov_direct' }
      }

      @user_identity = UserIdentity.new(normalized_attributes)
      @current_user = User.new(uuid: @user_identity.attributes[:uuid])
      @current_user.instance_variable_set(:@identity, @user_identity)
      @current_user.last_signed_in = Time.current.utc
      @session_object = Session.new(
        uuid: @current_user.uuid
      )

      @current_user.save && @session_object.save && @user_identity.save
      set_cookies
      # after_login_actions
      redirect_to "http://localhost:3001/auth/login/callback?type=logingov"
    end

    def set_cookies
      Rails.logger.info('[SignInService]: LOGIN', sso_logging_info)
      set_api_cookie!
    end
  end
end
