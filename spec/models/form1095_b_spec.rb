# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Form1095B, type: :model do
  subject { create :form1095_b }

  describe 'validations' do
    describe '#unique_icn_and_year' do
      context 'unique icn + year combo' do
        let(:dup) { subject.dup }

        it 'has unique icn and year' do
          expect(dup).not_to be_valid
        end
      end
    end
  end

  describe 'pdf_testing' do
    describe 'valid pdf generation' do
      it 'generates pdf string for valid 1095_b' do
        expect(subject.get_pdf.class).to eq(String)
      end
    end

    describe 'invalid PDF generation' do
      let(:inv_year_form) { create :form1095_b, veteran_icn: '654678976543678', tax_year: 2008 }

      it 'fails if no template PDF for the tax_year' do
        expect { inv_year_form.get_pdf }.to raise_error(RuntimeError, /1095-B for tax year 2008 not supported/)
      end
    end
  end
end
