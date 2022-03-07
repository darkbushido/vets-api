# frozen_string_literal: true

require 'common/client/configuration/rest'
require 'common/client/middleware/logging'
require 'sign_in/shared_configuration'

module SignIn::Logingov
  # Configuration for the Logingov::Service. A singleton class that returns
  # a connection that can make signed requests
  #
  # @example set the configuration in the service
  #   configuration Logingov::Configuration
  #
  class Configuration < Common::Client::Configuration::REST
    include SignIn::SharedConfiguration
    # Override the parent's base path
    # @return String the service base path from the environment settings
    #
    def base_path
      Settings.logingov.oauth_url
    end

    def client_id
      Settings.logingov.client_id
    end

    def redirect_uri
      Settings.logingov.redirect_uri
    end

    def client_key_path
      Settings.logingov.client_key_path
    end

    def client_cert_path
      Settings.logingov.client_cert_path
    end

    # Service name for breakers integration
    # @return String the service name
    def service_name
      'Logingov'
    end
  end
end
