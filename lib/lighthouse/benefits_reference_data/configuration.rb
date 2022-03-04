# frozen_string_literal: true

require 'common/client/configuration/rest'
require 'common/client/middleware/response/raise_error'

module Lighthouse
  module BenefitsReferenceData
    class Configuration < Common::Client::Configuration::REST
      def base_path
        Settings.lighthouse.benefits_reference_data.url
      end

      def service_name
        'Lighthouse/BenefitsReferenceData'
      end

      def self.base_request_headers
        super.merge('apiKey' => Settings.lighthouse.benefits_reference_data.api_key)
      end

      def connection
        Faraday.new(base_path, headers: base_request_headers, request: request_options) do |conn|
          conn.use :breakers
          conn.use :instrumentation, name: 'lighthouse.benefits_reference_data.request.faraday'

          # Uncomment this if you want curl command equivalent or response output to log
          # conn.request(:curl, ::Logger.new(STDOUT), :warn) unless Rails.env.production?
          # conn.response(:logger, ::Logger.new(STDOUT), bodies: true) unless Rails.env.production?

          # conn.response :raise_error, error_prefix: service_name
          # conn.response :lighthouse_benefits_reference_data_errors

          conn.adapter Faraday.default_adapter
        end
      end
    end
  end
end
