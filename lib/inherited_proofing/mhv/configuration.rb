# frozen_string_literal: true

require 'common/client/configuration/rest'

module InheritedProofing
  module MHV
    class Configuration < Common::Client::Configuration::REST
      def valid_id_url
        Settings.mhv.inherited_proofing.valid_id_url
      end

      def vacct_info_url
        Settings.mhv.inherited_proofing.vacct_info_url
      end

      def app_token
        Settings.mhv.rx.app_token
      end

      def base_path
        Settings.mhv.inherited_proofing.base_path
      end

      def service_name
        'mhv_inherited_proofing'
      end

      def connection
        Faraday.new(base_path, headers: base_request_headers, request: request_options) do |conn|
          conn.use :breakers
          conn.request :json
          conn.response :raise_error, error_prefix: service_name
          conn.adapter Faraday.default_adapter
        end
      end
    end
  end
end
