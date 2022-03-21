# frozen_string_literal: true

require 'mhv_inherited_proofing/mhv/configuration'

module MhvInheritedProofing::Mhv
  class Service < Common::Client::Base
    configuration MhvInheritedProofing::Mhv::Configuration

    attr_reader :user

    def intitialize(user)
      @user = user
    end

    def verified?
      identity_document_exists?
    end

    private

    def correlation_id
      mhv_api_request(correlation_id_url, 'correlationId')
    end

    def identity_document_exists?
      mhv_api_request(verification_info_url, 'identityDocumentExist')
    end

    def correlation_id_url
      "#{config.valid_id_url}/#{user.icn}"
    end

    def verification_info_url
      "#{config.vacct_info_url}/#{correlation_id}"
    end

    def mhv_api_request(url, attribute)
      response = perform(
        :get, url, nil, { 'appToken' => config.app_token, 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
      )
      response[attribute]
    rescue Common::Client::Errors::ClientError => e
      raise e
    end
  end
end
