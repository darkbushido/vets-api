# frozen_string_literal: true

require 'rails_helper'
require 'lighthouse/benefits_reference_data/configuration'

describe Lighthouse::BenefitsReferenceData::Configuration do
  describe '#service_name' do
    it 'has the expected service name' do
      expect(described_class.instance.service_name).to eq 'Lighthouse/BenefitsReferenceData'
    end
  end
end
