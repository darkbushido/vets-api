# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RapidReadyForDecision::Constants do
  let(:form526_submission) { create(:form526_submission, :hypertension_claim_for_increase) }

  describe 'processor_class and backup_processor_class' do
    it 'resolves all processor_class values to classes' do
      classes = RapidReadyForDecision::Constants::DISABILITIES.values.pluck(:processor_class).map(&:constantize)
      expect(classes.any?(&:nil?)).to eq false
    end

    it 'resolves all backup_processor_class values to classes' do
      classes = RapidReadyForDecision::Constants::DISABILITIES.values.pluck(:backup_processor_class)
                                                              .compact.map(&:constantize)
      expect(classes.any?(&:nil?)).to eq false
    end
  end

  describe '.extract_disability_symbol_list' do
    subject { described_class.extract_disability_symbol_list(form526_submission) }

    it 'returns list of matching DISABILITIES elements' do
      expect(subject).to eq [:hypertension]
    end

    context 'multiple RRD disabilities' do
      let(:form526_submission) { create(:form526_submission, :hypertension_and_asthma_claim_for_increase) }

      it 'returns list of DISABILITIES including hypertension and asthma' do
        expect(subject).to eq %i[hypertension asthma]
      end
    end

    context 'non-RRD disability' do
      let(:form526_submission) { create(:form526_submission, :hypertension_and_non_rrd_claim_for_increase) }

      it 'returns list of DISABILITIES with nil for non-RRD disability' do
        expect(subject).to eq [:hypertension, nil]
      end
    end
  end
end
