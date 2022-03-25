# frozen_string_literal: true

require 'inherited_proofing/mhv/configuration'

module InheritedProofing
  module MHV
    class Service < Common::Client::Base
      configuration InheritedProofing::MHV::Configuration

      def get_correlation_id_hash(icn)
        perform(:get, correlation_id_url(icn), nil, headers)
      rescue Common::Client::Errors::ClientError
        {}
      end

      def get_verification_hash(correlation_id)
        perform(:get, verification_info_url(correlation_id), nil, headers)
      rescue Common::Client::Errors::ClientError
        {}
      end

      private

      def correlation_id_url(icn)
        "#{config.valid_id_url}/#{icn}"
      end

      def verification_info_url(correlation_id)
        "#{config.vacct_info_url}/#{correlation_id}"
      end

      def headers
        { 'appToken' => config.app_token, 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
      end
    end
  end
end
