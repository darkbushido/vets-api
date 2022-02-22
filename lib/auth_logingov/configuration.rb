# frozen_string_literal: true

require 'common/client/configuration/rest'
require 'common/client/middleware/logging'

module AuthLogingov
  # Configuration for the AuthLogingov::Service. A singleton class that returns
  # a connection that can make signed requests
  #
  # @example set the configuration in the service
  #   configuration AuthLogingov::Configuration
  #
  class Configuration < Common::Client::Configuration::REST
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
    #
    def service_name
      'Logingov'
    end

    # Faraday connection object with breakers, snakecase and json response middleware
    # @return Faraday::Connection connection to make http calls
    #
    def connection
      @connection ||= Faraday.new(
        base_path, headers: base_request_headers, request: request_options, ssl: ssl_options
      ) do |conn|
        conn.use :breakers
        conn.use Faraday::Response::RaiseError
        conn.request(:curl, ::Logger.new(STDOUT), :warn) unless Rails.env.production?
        conn.response(:logger, ::Logger.new(STDOUT), bodies: true) unless Rails.env.production?
        conn.response :snakecase
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end
    end

    private

    def ssl_options
      if ssl_cert && ssl_key
        {
          client_cert: ssl_cert,
          client_key: ssl_key
        }
      end
    end

    def ssl_cert
      client_cert_path ? OpenSSL::X509::Certificate.new(File.read(client_cert_path)) : nil
    end

    def ssl_key
      client_key_path ? OpenSSL::PKey::RSA.new(File.read(client_key_path)) : nil
    end
  end
end
