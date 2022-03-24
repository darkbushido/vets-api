# frozen_string_literal: true

require 'inherited_proofing/mhv/configuration'

module InheritedProofing
  module MHV
    # This class will interact with MHV and return a hash of user data.
    # If the user is eligible for inherited proofing the result will be a
    # hash of identity data with an included code we will cache and send
    # to login.gov. If the user is not eligible the result will be a hash
    # of error information. If the entire service fails for whatever
    # reason the result will be an empty hash.
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
