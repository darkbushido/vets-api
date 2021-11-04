# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/ModuleLength
module AppealsApi
  module PdfConstruction
    module HigherLevelReview
      module V2
        describe FormFields do
          let(:form_fields) { described_class.new }

          describe 'middle_initial' do
            it { expect(form_fields.middle_initial).to eq 'form1[0].#subform[2].Veteran_Middle_Initial1[0]' }
          end

          describe 'first_three_ssn' do
            it do
              expect(
                form_fields.first_three_ssn
              ).to eq 'form1[0].#subform[2].ClaimantsSocialSecurityNumber_FirstThreeNumbers[0]'
            end
          end

          describe 'second_two_ssn' do
            it do
              expect(
                form_fields.second_two_ssn
              ).to eq 'form1[0].#subform[2].ClaimantsSocialSecurityNumber_SecondTwoNumbers[0]'
            end
          end

          describe 'last_four_ssn' do
            it do
              expect(
                form_fields.last_four_ssn
              ).to eq 'form1[0].#subform[2].ClaimantsSocialSecurityNumber_LastFourNumbers[0]'
            end
          end

          describe 'birth_month' do
            it { expect(form_fields.birth_month).to eq 'form1[0].#subform[2].DOBmonth[0]' }
          end

          describe 'birth_day' do
            it { expect(form_fields.birth_day).to eq 'form1[0].#subform[2].DOBday[0]' }
          end

          describe 'birth_year' do
            it { expect(form_fields.birth_year).to eq 'form1[0].#subform[2].DOByear[0]' }
          end

          describe 'file_number' do
            it { expect(form_fields.file_number).to eq 'form1[0].#subform[2].VAFileNumber[0]' }
          end

          describe 'service_number' do
            it { expect(form_fields.service_number).to eq 'F[0].#subform[2].VeteransServiceNumber[0]' }
          end

          describe 'insurance_policy_number' do
            it { expect(form_fields.insurance_policy_number).to eq 'form1[0].#subform[2].ClaimantsLastName[1]' }
          end

          describe 'mailing_address_street' do
            it do
              expect(
                form_fields.mailing_address_street
              ).to eq 'form1[0].#subform[2].CurrentMailingAddress_NumberAndStreet[0]'
            end
          end

          describe 'mailing_address_unit_number' do
            it do
              expect(
                form_fields.mailing_address_unit_number
              ).to eq 'form1[0].#subform[2].CurrentMailingAddress_ApartmentOrUnitNumber[0]'
            end
          end

          describe 'mailing_address_city' do
            it { expect(form_fields.mailing_address_city).to eq 'form1[0].#subform[2].CurrentMailingAddress_City[0]' }
          end

          describe 'mailing_address_state' do
            it do
              expect(
                form_fields.mailing_address_state
              ).to eq 'form1[0].#subform[2].CurrentMailingAddress_StateOrProvince[0]'
            end
          end

          describe 'mailing_address_country' do
            it do
              expect(form_fields.mailing_address_country).to eq 'form1[0].#subform[2].CurrentMailingAddress_Country[0]'
            end
          end

          describe 'mailing_address_zip_first_5' do
            it do
              expect(
                form_fields.mailing_address_zip_first_5
              ).to eq 'form1[0].#subform[2].CurrentMailingAddress_ZIPOrPostalCode_FirstFiveNumbers[0]'
            end
          end

          describe 'mailing_address_zip_last_4' do
            it do
              expect(
                form_fields.mailing_address_zip_last_4
              ).to eq 'form1[0].#subform[2].CurrentMailingAddress_ZIPOrPostalCode_LastFourNumbers[0]'
            end
          end

          describe 'veteran_homeless' do
            it { expect(form_fields.veteran_homeless).to eq 'form1[0].#subform[2].ClaimantType[0]' }
          end

          describe 'veteran_phone_area_code' do
            it do
              expect(form_fields.veteran_phone_area_code).to eq 'form1[0].#subform[2].Daytime_Phone_Number_Area_Code[0]'
            end
          end

          describe 'veteran_phone_prefix' do
            it do
              expect(
                form_fields.veteran_phone_prefix
              ).to eq 'form1[0].#subform[2].Daytime_Phone_Middle_Three_Numbers[0]'
            end
          end

          describe 'veteran_phone_line_number' do
            it do
              expect(
                form_fields.veteran_phone_line_number
              ).to eq 'form1[0].#subform[2].Daytime_Phone_Last_Four_Numbers[0]'
            end
          end

          describe 'veteran_phone_international_number' do
            it do
              expect(
                form_fields.veteran_phone_international_number
              ).to eq 'form1[0].#subform[2].International_Telephone_Number_If_Applicable[0]'
            end
          end

          describe 'veteran_email' do
            it do
              expect(form_fields.veteran_email).to eq 'form1[0].#subform[2].CurrentMailingAddress_NumberAndStreet[2]'
            end
          end

          describe 'benefit_type(index)' do
            it do
              expect(form_fields.benefit_type(1)).to eq 'form1[0].#subform[2].BenefitType[1]'
            end
          end

          describe 'informal_conference' do
            it { expect(form_fields.informal_conference).to eq 'form1[0].#subform[3].HIGHERLEVELREVIEWCHECKBOX[0]' }
          end

          describe 'conference_8_to_12' do
            it { expect(form_fields.conference_8_to_12).to eq 'form1[0].#subform[3].TIME8TO10AM[0]' }
          end

          describe 'conference_12_to_1630' do
            it { expect(form_fields.conference_12_to_1630).to eq 'form1[0].#subform[3].TIME1230TO2PM[0]' }
          end

          describe 'conference_rep_8_to_12' do
            it { expect(form_fields.conference_rep_8_to_12).to eq 'form1[0].#subform[3].TIME10TO1230PM[0]' }
          end

          describe 'conference_rep_12_to_1630' do
            it { expect(form_fields.conference_rep_12_to_1630).to eq 'form1[0].#subform[3].TIME2TO430PM[0]' }
          end

          describe 'rep_phone_area_code' do
            it do
              expect(form_fields.rep_phone_area_code).to eq 'form1[0].#subform[3].Daytime_Phone_Number_Area_Code[2]'
            end
          end

          describe 'rep_phone_prefix' do
            it do
              expect(form_fields.rep_phone_prefix).to eq 'form1[0].#subform[3].Daytime_Phone_Middle_Three_Numbers[2]'
            end
          end

          describe 'rep_phone_line_number' do
            it do
              expect(form_fields.rep_phone_line_number).to eq 'form1[0].#subform[3].Daytime_Phone_Last_Four_Numbers[2]'
            end
          end

          describe 'rep_email' do
            it { expect(form_fields.rep_email).to eq 'form1[0].#subform[3].CurrentMailingAddress_NumberAndStreet[4]' }
          end

          describe 'sso_ssoc_opt_in' do
            it { expect(form_fields.sso_ssoc_opt_in).to eq 'form1[0].#subform[3].RadioButtonList[0]' }
          end

          describe 'signature' do
            it { expect(form_fields.signature).to eq 'form1[0].#subform[4].SIGNATUREOFVETERANORCLAIMANT[0]' }
          end

          describe 'date_signed_month' do
            it { expect(form_fields.date_signed_month).to eq 'form1[0].#subform[4].DOBmonth[15]' }
          end

          describe 'date_signed_day' do
            it { expect(form_fields.date_signed_day).to eq 'form1[0].#subform[4].DOBday[15]' }
          end

          describe 'date_signed_year' do
            it { expect(form_fields.date_signed_year).to eq 'form1[0].#subform[4].DOByear[15]' }
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
