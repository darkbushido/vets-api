# frozen_string_literal: true

require 'uri'
require 'sign_in/url_service'
require 'sign_in/logingov/configuration'

module SignIn::Idme
  class Service < Common::Client::Base
    configuration SignIn::Idme::Configuration
  end
end
