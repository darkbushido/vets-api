# frozen_string_literal: true

###
# Both CountriesResponse and StatesResponse returns an array of strings
# containing country names and state abbreviations, respectively.
#
##
# Example of successful CountriesResponse:

#   {
#     "totalItems": 0,
#     "totalPages": 0,
#     "links": [
#       {
#         "href": "string",
#         "rel": "strin"
#       }
#     ],
#     "items": [
#       "Canada"
#     ]
#   }

##
# Example of successful StatesResponse:

#   {
#     "totalItems": 0,
#     "totalPages": 0,
#     "links": [
#       {
#         "href": "string",
#         "rel": "strin"
#       }
#     ],
#     "items": [
#       "MN"
#     ]
#   }
#

require 'common/models/base'
require_relative 'countries_list'
require_relative 'states_list'

module Lighthouse
  module BenefitsReferenceData
    class Response < Common::Base

      attribute :body, String
      attribute :status, Integer
      attribute :items, Object
      attribute :links, Object
      attribute :total_items, Integer
      attribute :total_pages, Integer

      def initialize(body, status)
        super()
        self.body = body
        self.status = status
        parsed_body = JSON.parse(body)
        self.items = parsed_body['items']
        self.links = parsed_body['links']
        self.total_items = parsed_body['totalItems']
        self.total_pages = parsed_body['totalPages']
      end

      def countries
        Lighthouse::BenefitsReferenceData::CountriesList.new(items)
      end

      def states
        Lighthouse::BenefitsReferenceData::StatesList.new(items)
      end
    end
  end
end
