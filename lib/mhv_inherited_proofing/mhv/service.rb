# frozen_string_literal: true

require 'mhv_inherited_proofing/mhv/configuration'

module MhvInheritedProofing::Mhv
  class Service < Common::Client::Base
    configuration MhvInheritedProofing::Mhv::Configuration

    def correlation_id
      response = perform(
        :get, "#{config.valid_id_url}/#{ICN}", nil, { 'appToken' => config.app_token, 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
      )
      response['correlationId']
    rescue e
      raise e
    end
  end
end
