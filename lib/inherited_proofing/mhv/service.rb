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

      def identity_proof_data
        return {} if correlation_id.blank?

        data_hsh = mhv_api_request(verification_info_url)
        data_hsh['identityDocumentExist'].present? ? data_hsh.merge('code' => code) : data_hsh
      end

      private

      def correlation_id
        @correlation_id ||= user.mhv_correlation_id.presence || mhv_api_request(correlation_id_url)['correlationId']
      end

      def correlation_id_url
        "#{config.valid_id_url}/#{user.icn}"
      end

      def verification_info_url
        "#{config.vacct_info_url}/#{correlation_id}"
      end

      def mhv_api_request(url)
        perform(:get, url, nil, headers)
      rescue Common::Client::Errors::ClientError
        {}
      end

      def headers
        { 'appToken' => config.app_token, 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
      end

      def code
        SecureRandom.hex
      end
    end
  end
end
