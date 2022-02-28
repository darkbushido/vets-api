# frozen_string_literal: true

require 'auth/logingov/service'

module V2
  class SessionsController < ApplicationController
    skip_before_action :verify_authenticity_token

    NO_AUTH_ACTIONS = %w[new].freeze
    REDIRECT_URLS = %w[idme logingov].freeze

    def new
      render_login
    end

    def callback
      response = auth_service.token(params[:code])
      user_info = auth_service.user_info(response[:access_token])
      user_login(user_info)
    rescue => e
      handle_callback_error(e, :failure, :error)
    end

    private

    def render_login
      render body: auth_service.render_auth, content_type: 'text/html'
    end

    def handle_callback_error(err, status, level = :error, code = SAML::Responses::Base::UNKNOWN_OR_BLANK_ERROR_CODE)
      message = err&.message || ''
      log_message_to_sentry(message, level)
      redirect_to auth_service.login_redirect_url(auth: 'fail', code: code) unless performed?
      # add login_stats/callback_stats/PersonalInformationLog
    end

    def user_login(user_info)
      normalized_attributes = auth_service.normalized_attributes(user_info)

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
      redirect_to auth_service.login_redirect_url(auth: 'success')
    end

    def authenticate
      return unless NO_AUTH_ACTIONS.include?(action_name)

      reset_session
    end

    def set_cookies
      Rails.logger.info('[SignInService]: LOGIN', sso_logging_info)
      set_api_cookie!
    end

    def auth_service
      type = params[:type]
      case type
      when 'idme'
        idme_auth_service
      when 'logingov'
        logingov_auth_service
      end
    end

    def idme_auth_service
    end

    def logingov_auth_service
      @logingov_auth_service ||= AuthLogingov::Service.new
    end
  end
end
