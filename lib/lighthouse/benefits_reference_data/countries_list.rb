# frozen_string_literal: true

require 'common/models/base'

module Lighthouse
  module BenefitsReferenceData
    class CountriesList < Common::Base
      include ActiveModel::Serializers::JSON

      attribute :countries, Array

      def initialize(items = {})
        super(items)

        self.countries = items
      end
    end
  end
end
