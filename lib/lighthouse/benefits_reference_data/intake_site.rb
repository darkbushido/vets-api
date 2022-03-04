# frozen_string_literal: true

require 'common/models/base'

# BenefitsReferenceData Model
module Lighthouse
  module BenefitsReferenceData
    class IntakeSite < Common::Base
      include ActiveModel::Serializers::JSON

      attribute :id, Object
      attribute :description, Object

      def initialize(intake_site)
        super(intake_site)

        self.id = intake_site['id']
        self.description = intake_site['description']
      end
    end
  end
end
