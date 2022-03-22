# frozen_string_literal: true

require 'inherited_proofing/mhv/configuration'

module InheritedProofing
  module MHV
    class Service < Common::Client::Base
      configuration InheritedProofing::MHV::Configuration

      attr_reader :user

      def initialize(user)
        @user = user
      end

      def verified?
        identity_document_exists?
      end

      private

      def correlation_id
        user.mhv_correlation_id.presence || mhv_api_request(correlation_id_url)['correlationId']
      end

      def identity_document_exists?
        mhv_api_request(verification_info_url)['identityDocumentExist']
      end

      def correlation_id_url
        "#{config.valid_id_url}/#{user.icn}"
      end

      def verification_info_url
        "#{config.vacct_info_url}/#{correlation_id}"
      end

      def mhv_api_request(url)
        response = perform(:get, url, nil, headers)
      rescue Common::Client::Errors::ClientError => e
        raise e
      end

      def headers
        { 'appToken' => config.app_token, 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
      end
    end
  end
end
