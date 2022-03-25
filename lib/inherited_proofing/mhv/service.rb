# frozen_string_literal: true

require 'inherited_proofing/mhv/configuration'

module InheritedProofing
  module MHV
    class Service
      def self.get_correlation_data(icn)
        ConfigMethods.new.correlation_id_api_request(icn)
      end

<<<<<<< HEAD
      def self.get_verification_data(correlation_id)
        ConfigMethods.new.verification_info_api_request(correlation_id)
=======
      def identity_proof_data
        return {} if correlation_id.blank?

        data_hsh = mhv_api_request(verification_info_url)
        require 'pry'; binding.pry
        data_hsh['identityDocumentExist'].present? ? data_hsh.merge('code' => code) : data_hsh
>>>>>>> adds inherited_proofing_controller spec
      end

      class ConfigMethods < Common::Client::Base
        configuration InheritedProofing::MHV::Configuration

        def correlation_id_url(icn)
          "#{config.valid_id_url}/#{icn}"
        end

        def verification_info_url(correlation_id)
          "#{config.vacct_info_url}/#{correlation_id}"
        end

        def headers
          { 'appToken' => config.app_token, 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
        end

        def correlation_id_api_request(icn)
          response = perform(:get, correlation_id_url(icn), nil, headers)
          JSON.parse(response.body)
        rescue Common::Client::Errors::ClientError
          {}
        end

        def verification_info_api_request(correlation_id)
          response = perform(:get, verification_info_url(correlation_id), nil, headers)
          JSON.parse(response.body)
        rescue Common::Client::Errors::ClientError
          {}
        end
      end
    end
  end
end
