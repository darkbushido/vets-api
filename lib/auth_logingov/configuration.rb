# frozen_string_literal: true

require 'common/client/configuration/rest'

module AuthLogingov
  # Configuration for the AuthLogingov::Service. A singleton class that returns
  # a connection that can make signed requests
  #
  # @example set the configuration in the service
  #   configuration AuthLogingov::Configuration
  #
  class Configuration < Common::Client::Configuration::REST
    CERT_PATH = Settings.logingov.client_cert_path
    KEY_PATH = Settings.logingov.client_key_path

    # Override the parent's base path
    # @return String the service base path from the environment settings
    #
    def base_path
      Settings.logingov.oauth_url
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
      CERT_PATH ? OpenSSL::X509::Certificate.new(File.read(CERT_PATH)) : nil
    end

    def ssl_key
      KEY_PATH ? OpenSSL::PKey::RSA.new(File.read(KEY_PATH)) : nil
    end
  end
end
