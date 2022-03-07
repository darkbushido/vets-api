# frozen_string_literal: true

require 'common/client/configuration/rest'
require 'common/client/middleware/logging'
require 'sign_in/shared_configuration'

module SignIn::Idme
  class Configuration < Common::Client::Configuration::REST
    include SignIn::SharedConfiguration

    def base_path
      Settings.idme.oauth_url
    end

    def client_id
      Settings.idme.client_id
    end

    def redirect_uri
      Settings.idme.redirect_uri
    end

    def client_key_path
      Settings.idme.client_key_path
    end

    def client_cert_path
      Settings.idme.client_cert_path
    end

    def service_name
      'Idme'
    end
  end
end
