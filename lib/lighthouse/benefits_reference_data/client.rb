# frozen_string_literal: true

require 'common/client/base'
require_relative 'configuration'
require_relative 'response_strategy'
require_relative 'response' # countries, states response
require_relative 'intake_sites_response'

module Lighthouse
  module BenefitsReferenceData
    class Client < Common::Client::Base
      configuration Lighthouse::BenefitsReferenceData::Configuration

      ##
      # Retrieve a list of countries.
      #
      # Provides a current list of Countries, standardized by the VA,
      # which can be used for completing a Veteran's benefits profile
      # or patient contact information update (PCIU) such as "Bolivia", "China", or "Serbia/Montenegro".
      #
      # Example request:
      #
      # curl -X GET 'https://sandbox-api.va.gov/services/benefits-reference-data/v1/countries'
      #
      # Request params:
      #
      # * page - An integer indicationg the page of results requested
      # * page_size - An integer indicating the maximum number of results.
      #
      # Example JSON response:
      #
      # {
      #   "totalItems": 0,
      #   "totalPages": 0,
      #   "links": [
      #     {
      #       "href": "string",
      #       "rel": "string"
      #     }
      #   ],
      #   "items": [
      #     "Canada"
      #   ]
      # }
      #
      def get_countries(params = {})
        response = perform(:get, '/services/benefits-reference-data/v1/countries', params)
        return response unless response.status == 200

        Lighthouse::BenefitsReferenceData::Response.new(response.body, response.status).countries
      end

      ##
      # Retrieve a list of states.
      #
      # A current list of States (including US territories and key
      # military mail hubs) standardized by the VA, which can be used
      # for completing a Veteran's benefits profile or patient contact
      # information update (PCIU) such as "FL", "GU", or "PW".
      #
      # Example request:
      #
      # * curl -X GET 'https://sandbox-api.va.gov/services/benefits-reference-data/v1/states'
      #
      # Request params:
      #
      # * page - An integer indicationg the page of results requested
      # * page_size - An integer indicating the maximum number of results.
      #
      # Example JSON response:
      #
      # {
      #   "totalItems": 0,
      #   "totalPages": 0,
      #   "links": [
      #     {
      #       "href": "string",
      #       "rel": "string"
      #     }
      #   ],
      #   "items": [
      #     "MN"
      #   ]
      # }
      #
      def get_states(params = {})
        response = perform(:get, '/services/benefits-reference-data/v1/states', params)
        return response unless response.status == 200

        Lighthouse::BenefitsReferenceData::Response.new(response.body, response.status).states
      end

      ##
      # Retrieve a list of intake sites.
      #
      # The location where a Veteran's military separation process will occur
      # such as "Andrews AFB", "Fort Sam Houston", or "Moody AFB".
      #
      # Example request:
      #
      # * curl -X GET 'https://sandbox-api.va.gov/services/benefits-reference-data/v1/intake-sites'
      #
      # Request params:
      #
      # * page - An integer indicationg the page of results requested
      # * page_size - An integer indicating the maximum number of results.
      #
      # Example JSON response:
      #
      # {
      #   "totalItems": 0,
      #   "totalPages": 0,
      #   "links": [
      #     {
      #       "href": "string",
      #       "rel": "strin"
      #     }
      #   ],
      #   "items": [
      #     {
      #       "id": 5674661,
      #       "description": "AF Academy"
      #     }
      #   ]
      # }
      #
      def get_separation_locations(params = {})
        response = perform(:get, '/services/benefits-reference-data/v1/intake-sites', params)
        return response unless response.status == 200

        Lighthouse::BenefitsReferenceData::IntakeSitesResponse.new(response.body, response.status).intake_sites
      end
    end
  end
end
