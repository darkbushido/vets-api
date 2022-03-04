# frozen_string_literal: true

require 'common/models/base'

module Lighthouse
  module BenefitsReferenceData
    class StatesList < Common::Base
      include ActiveModel::Serializers::JSON

      attribute :states, Array

      def initialize(items)
        super(items)

        self.countries = items
      end
    end
  end
end
