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
      response = logingov_auth_service.token(params[:code])
      user_info = logingov_auth_service.user_info(response[:access_token])
      user_login(user_info)
    rescue => e
      handle_callback_error(e, :failure, :error)
    end

    private

    def handle_callback_error(err, status, level = :error, code = SAML::Responses::Base::UNKNOWN_OR_BLANK_ERROR_CODE)
      message = err&.message || ''
      log_message_to_sentry(message, level)
      redirect_to logingov_auth_service.login_redirect_url(auth: 'fail', code: code) unless performed?
      # add login_stats/callback_stats/PersonalInformationLog
    end

    def render_login
      render body: auth_service.render_auth, content_type: 'text/html'
    end

    def auth_service
      type = params[:type]
      raise Common::Exceptions::RoutingError, type unless REDIRECT_URLS.include?(type)

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
      redirect_to logingov_auth_service.login_redirect_url(auth: 'success')
    end

    def set_cookies
      Rails.logger.info('[SignInService]: LOGIN', sso_logging_info)
      set_api_cookie!
    end
  end
end
