# frozen_string_literal: true

##
# IntakeSiteResponse Example
#
# Intake Sites retrieved successfully.
#
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
#       {
#         "id": 5674661,
#         "description": "AF Academy"
#       }
#     ]
#   }
#

require 'common/models/base'
require_relative 'intake_site'

module Lighthouse
  module BenefitsReferenceData
    class IntakeSitesResponse < Common::Base
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
      end

      def intake_sites
        items.map do |item|
          Lighthouse::BenefitsReferenceData::IntakeSite.new(item)
        end
      end
    end
  end
end
