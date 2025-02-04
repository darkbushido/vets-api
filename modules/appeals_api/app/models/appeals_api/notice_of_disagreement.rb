# frozen_string_literal: true

require 'json_marshal/marshaller'
require 'common/exceptions'

module AppealsApi
  class NoticeOfDisagreement < ApplicationRecord
    include NodStatus
    include PdfOutputPrep

    attr_readonly :auth_headers
    attr_readonly :form_data

    scope :pii_expunge_policy, lambda {
      where(
        status: COMPLETE_STATUSES
      ).and(
        where('updated_at < ? AND board_review_option IN (?)', 1.week.ago, %w[hearing direct_review])
        .or(where('updated_at < ? AND board_review_option IN (?)', 91.days.ago, 'evidence_submission'))
      )
    }

    def self.load_json_schema(filename)
      MultiJson.load File.read Rails.root.join('modules', 'appeals_api', 'config', 'schemas', "#{filename}.json")
    end

    def self.date_from_string(string)
      string.match(/\d{4}-\d{2}-\d{2}/) && Date.parse(string)
    rescue ArgumentError
      nil
    end

    serialize :auth_headers, JsonMarshal::Marshaller
    serialize :form_data, JsonMarshal::Marshaller
    has_kms_key
    encrypts :auth_headers, :form_data, key: :kms_key, **lockbox_options

    validate :validate_hearing_type_selection, if: :pii_present?
    validate :validate_extension_request, if: :version_2?

    has_many :evidence_submissions, as: :supportable, dependent: :destroy
    has_many :status_updates, as: :statusable, dependent: :destroy

    def pdf_structure(version)
      Object.const_get(
        "AppealsApi::PdfConstruction::NoticeOfDisagreement::#{version.upcase}::Structure"
      ).new(self)
    end

    # V2 Specific
    def veteran
      @veteran ||= Appellant.new(
        type: :veteran,
        auth_headers: auth_headers,
        form_data: data_attributes&.dig('veteran')
      )
    end

    def claimant
      @claimant ||= Appellant.new(
        type: :claimant,
        auth_headers: auth_headers,
        form_data: data_attributes&.dig('claimant')
      )
    end

    def signing_appellant
      claimant.signing_appellant? ? claimant : veteran
    end

    def appellant_local_time
      signing_appellant.timezone ? created_at.in_time_zone(signing_appellant.timezone) : created_at.utc
    end

    def extension_request?
      data_attributes['extensionRequest'] && extension_reason.present?
    end

    def extension_reason
      data_attributes['extensionReason']
    end

    def appealing_vha_denial?
      data_attributes['appealingVhaDenial']
    end

    def contestable_issues
      form_data&.dig('included')
    end

    def representative
      data_attributes['representative']
    end
    # V2 End

    def veteran_first_name
      header_field_as_string 'X-VA-First-Name'
    end

    def veteran_last_name
      header_field_as_string 'X-VA-Last-Name'
    end

    def ssn
      header_field_as_string 'X-VA-SSN'
    end

    def file_number
      header_field_as_string 'X-VA-File-Number'
    end

    def consumer_name
      header_field_as_string 'X-Consumer-Username'
    end

    def consumer_id
      header_field_as_string 'X-Consumer-ID'
    end

    def veteran_contact_info
      form_data&.dig('data', 'attributes', 'veteran')
    end

    def mailing_address
      address_combined = [
        veteran_contact_info.dig('address', 'addressLine1'),
        veteran_contact_info.dig('address', 'addressLine2'),
        veteran_contact_info.dig('address', 'addressLine3')
      ].compact.map(&:strip).join(' ')

      [
        address_combined,
        veteran_contact_info.dig('address', 'city'),
        veteran_contact_info.dig('address', 'stateCode'),
        zip_code_5_or_international_postal_code,
        veteran_contact_info.dig('address', 'countryName')
      ].compact.map(&:strip).join(', ')
    end

    def phone
      AppealsApi::HigherLevelReview::Phone.new(veteran_contact_info&.dig('phone')).to_s
    end

    def email
      # V2 and V1 access the email data via different keys ('email' vs 'emailAddressText')
      signing_appellant.email.presence || veteran_contact_info['emailAddressText']
    end

    def veteran_homeless?
      form_data&.dig('data', 'attributes', 'veteran', 'homeless')
    end

    def representative_name
      form_data&.dig('data', 'attributes', 'veteran', 'representativesName')
    end

    def board_review_value
      form_data&.dig('data', 'attributes', 'boardReviewOption')
    end

    def hearing_type_preference
      form_data&.dig('data', 'attributes', 'hearingTypePreference')
    end

    def zip_code_5
      # schema already validated address presence if not homeless
      veteran_contact_info&.dig('address', 'zipCode5') || '00000'
    end

    def zip_code_5_or_international_postal_code
      zip = zip_code_5
      return zip unless zip == '00000'

      veteran_contact_info&.dig('address', 'internationalPostalCode')
    end

    def lob
      'BVA'
    end

    def accepts_evidence?
      board_review_option == 'evidence_submission'
    end

    def evidence_submission_days_window
      91
    end

    def outside_submission_window_error
      {
        title: 'unprocessable_entity',
        detail: I18n.t('appeals_api.errors.nod_outside_legal_window'),
        code: 'OutsideLegalWindow',
        status: '422'
      }
    end

    def update_status!(status:, code: nil, detail: nil)
      handler = Events::Handler.new(event_type: :nod_status_updated, opts: {
                                      from: self.status,
                                      to: status.to_s,
                                      status_update_time: Time.zone.now.iso8601,
                                      statusable_id: id
                                    })

      email_handler = Events::Handler.new(event_type: :nod_received, opts: {
                                            email_identifier: email_identifier,
                                            first_name: veteran_first_name,
                                            date_submitted: veterans_local_time.iso8601,
                                            guid: id,
                                            claimant_email: claimant.email,
                                            claimant_first_name: claimant.first_name
                                          })

      update!(status: status, code: code, detail: detail)

      handler.handle!
      email_handler.handle! if status == 'submitted' && (claimant.email.present? || email_identifier.present?)
    end

    private

    def mpi_veteran
      AppealsApi::Veteran.new(
        ssn: ssn,
        first_name: veteran_first_name,
        last_name: veteran_last_name,
        birth_date: birth_date.iso8601
      )
    end

    def email_identifier
      return { id_type: 'email', id_value: email } if email.present?

      icn = mpi_veteran.mpi_icn

      return { id_type: 'ICN', id_value: icn } if icn.present?
    end

    def data_attributes
      form_data&.dig('data', 'attributes')
    end

    def veterans_local_time
      veterans_timezone ? created_at.in_time_zone(veterans_timezone) : created_at.utc
    end

    def veterans_timezone
      data_attributes&.dig('timezone').presence&.strip
    end

    def validate_hearing_type_selection
      return if board_review_hearing_selected? && includes_hearing_type_preference?

      source = '/data/attributes/hearingTypePreference'
      data = I18n.t('common.exceptions.validation_errors')

      if hearing_type_missing?
        errors.add source, data.merge(detail: I18n.t('appeals_api.errors.hearing_type_preference_missing'))
      elsif unexpected_hearing_type_inclusion?
        errors.add source, data.merge(detail: I18n.t('appeals_api.errors.hearing_type_preference_inclusion'))
      end
    end

    # v2 specific validation
    def validate_extension_request
      # json schema will have already validated that if extensionRequest true then extensionReason required
      return if data_attributes&.dig('extensionRequest') == true

      source = '/data/attributes/extensionRequest'
      data = I18n.t('common.exceptions.validation_errors')

      if data_attributes&.dig('extensionReason').present?
        errors.add source,
                   data.merge(detail: I18n.t('appeals_api.errors.nod_extension_request_must_be_true'))
      end
    end

    def board_review_hearing_selected?
      board_review_value == 'hearing'
    end

    def includes_hearing_type_preference?
      hearing_type_preference.present?
    end

    def hearing_type_missing?
      board_review_hearing_selected? && !includes_hearing_type_preference?
    end

    def unexpected_hearing_type_inclusion?
      !board_review_hearing_selected? && includes_hearing_type_preference?
    end

    def birth_date
      self.class.date_from_string header_field_as_string 'X-VA-Birth-Date'
    end

    def header_field_as_string(key)
      auth_headers&.dig(key).to_s.strip
    end

    def version_2?
      pii_present? && api_version == 'v2'
    end

    # After expunging pii, form_data is nil, update will fail unless validation skipped
    def pii_present?
      proc { |a| a.form_data.present? }
    end

    def clear_memoized_values
      @veteran = @claimant = nil
    end
  end
end
