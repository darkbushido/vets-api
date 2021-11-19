# frozen_string_literal: true

require 'evss/common_service'
require 'evss/disability_compensation_auth_headers'
require 'evss/disability_compensation_form/form4142'
require 'evss/disability_compensation_form/service'
require 'evss/reference_data/service'
require 'evss/reference_data/response_strategy'

module V0
  class DisabilityCompensationFormsController < ApplicationController
    before_action { authorize :evss, :access? }
    before_action :validate_name_part, only: [:suggested_conditions]

    def rated_disabilities
      response = service.get_rated_disabilities
      render json: response,
             serializer: RatedDisabilitiesSerializer
    end

    def separation_locations
      response = EVSS::ReferenceData::ResponseStrategy.new.cache_by_user_and_type(
        :all_users,
        :get_separation_locations
      ) do
        EVSS::ReferenceData::Service.new(@current_user).get_separation_locations
      end

      render json: response, each_serializer: EVSSSeparationLocationSerializer
    end

    def suggested_conditions
      results = DisabilityContention.suggested(params[:name_part])
      render json: results, each_serializer: DisabilityContentionSerializer
    end

    def submit_all_claim
      form_content = JSON.parse(request.body.string)
      # Check for and assign special issue to single issue increase only hypertension claim
      add_ht_special_issue(form) if Flipper.enabled?(:disability_hypertension_compensation_fast_track, current_user) &&
                                    ht_special_issue_claim?(form)
      saved_claim = SavedClaim::DisabilityCompensation::Form526AllClaim.from_hash(form_content)
      saved_claim.save ? log_success(saved_claim) : log_failure(saved_claim)
      submission = create_submission(saved_claim)

      jid = submission.start

      render json: { data: { attributes: { job_id: jid } } },
             status: :ok
    end

    def submission_status
      job_status = Form526JobStatus.where(job_id: params[:job_id]).first
      raise Common::Exceptions::RecordNotFound, params[:job_id] unless job_status

      render json: job_status, serializer: Form526JobStatusSerializer
    end

    def rating_info
      rating_info_service = EVSS::CommonService.new(auth_headers)
      response = rating_info_service.get_rating_info
      render json: response,
             serializer: RatingInfoSerializer
    end

    private

    def create_submission(saved_claim)
      Rails.logger.info(
        'Creating 526 submission', user_uuid: @current_user&.uuid, saved_claim_id: saved_claim&.id
      )
      submission = Form526Submission.new(
        user_uuid: @current_user.uuid,
        saved_claim_id: saved_claim.id,
        auth_headers_json: auth_headers.to_json,
        form_json: saved_claim.to_submission_data(@current_user)
      ) { |sub| sub.add_birls_ids @current_user.mpi_birls_id }
      submission.save! && submission
    rescue PG::NotNullViolation => e
      Rails.logger.error(
        'Creating 526 submission: PG::NotNullViolation', user_uuid: @current_user&.uuid, saved_claim_id: saved_claim&.id
      )
      raise e
    end

    def ht_special_issue_claim?(form)
      begin 
        # Must have only 1 actionable issue, and its gots to be hypertension(7101) increase only
        rd = form.dig('form526', 'ratedDisabilities')&.select { |dis| dis['disabilityActionType'] != 'NONE' }
        return false unless rd&.length.to_i == 1
        return false unless rd[0]['diagnosticCode'] == 7101
        return false unless rd[0]['disabilityActionType'] == 'INCREASE'

        # No new issues
        return false unless form.dig('form526', 'newDisabilities')&.length.to_i.zero?

        true
      rescue => e
        Rails.logger.error "Form 526 Hypertension check failed. Form=#{claim.class::FORM} user uuid=#{@current_user&.uuid} ex=#{e.message}"
        false
      end
    end

    def add_ht_special_issue(form)
      begin
        # find hypertension issue and add RDD SI
        form['form526']['ratedDisabilities'].map! do |dis|
          if dis['diagnosticCode'] == 7101
            dis['specialIssues'] ||= []
            dis['specialIssues'] << 'RRD' if dis['specialIssues'].exclude? 'RRD'
          end
          dis
      rescue => e
        Rails.logger.error "Form 526 Hypertension add SI failed. Form=#{claim.class::FORM} user uuid=#{@current_user&.uuid} ex=#{e.message}"
      end
    end

    def log_failure(claim)
      StatsD.increment("#{stats_key}.failure")
      raise Common::Exceptions::ValidationErrors, claim
    end

    def log_success(claim)
      StatsD.increment("#{stats_key}.success")
      Rails.logger.info "ClaimID=#{claim.confirmation_number} Form=#{claim.class::FORM}"
    end

    def translate_form4142(form_content)
      EVSS::DisabilityCompensationForm::Form4142.new(@current_user, form_content).translate
    end

    def validate_name_part
      raise Common::Exceptions::ParameterMissing, 'name_part' if params[:name_part].blank?
    end

    def service
      EVSS::DisabilityCompensationForm::Service.new(auth_headers)
    end

    def auth_headers
      EVSS::DisabilityCompensationAuthHeaders.new(@current_user).add_headers(EVSS::AuthHeaders.new(@current_user).to_h)
    end

    def stats_key
      'api.disability_compensation'
    end
  end
end
