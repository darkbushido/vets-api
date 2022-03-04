# frozen_string_literal: true

require 'common/client/configuration/rest'
require 'common/client/middleware/logging'

module SignIn::Idme
  class Configuration < Common::Client::Configuration::REST
  end
end
