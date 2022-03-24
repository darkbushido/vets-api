# frozen_string_literal: true

module RapidReadyForDecision
  class ProcessorSelector
    def initialize(form526_submission)
      @form526_submission = form526_submission
    end

    def processor_class(backup: false)
      return nil unless rrd_enabled?

      if rrd_enabled_disability?('hypertension') && single_issue_claim_applicable?(DiagnosticCodes::HYPERTENSION)
        return RapidReadyForDecision::DisabilityCompensationJob if backup

        return RapidReadyForDecision::Form526HypertensionJob
      end

      if rrd_enabled_disability?('asthma') && single_issue_claim_applicable?(DiagnosticCodes::ASTHMA)
        return RapidReadyForDecision::Form526AsthmaJob
      end

      nil
    end

    def rrd_applicable?
      !processor_class.nil?
    end

    def self.disability_increase?(disability, diagnostic_code)
      disability['diagnosticCode'] == diagnostic_code &&
        disability['disabilityActionType']&.upcase == 'INCREASE'
    end

    def send_rrd_alert(message)
      body = <<~BODY
        Environment: #{Settings.vsp_environment}<br/>
        Form526Submission.id: #{@form526_submission.id}<br/>
        <br/>
        #{message}
      BODY
      ActionMailer::Base.mail(
        from: ApplicationMailer.default[:from],
        to: Settings.rrd.alerts.recipients,
        subject: 'RRD Processor Selector alert',
        body: body
      ).deliver_now
    end

    private

    def rrd_enabled?
      # In next PR, change this to be a Flipper configuration to disable RRD completely
      true
    end

    # @return [Boolean] Is the specified disability RRD-enabled according to Flipper settings
    def rrd_enabled_disability?(disability)
      # Todo later: Remove old RRD-related Flipper keys "disability_#{disability.downcase}_compensation_fast_track"
      Flipper.enabled?("rrd_#{disability.downcase}_compensation".to_sym) ||
        Flipper.enabled?("disability_#{disability.downcase}_compensation_fast_track".to_sym)
    end

    def form_disabilities
      @form_disabilities ||= @form526_submission.form.dig('form526', 'form526', 'disabilities')
    end

    def single_issue_claim_applicable?(diagnostic_code)
      form_disabilities.count == 1 &&
        self.class.disability_increase?(form_disabilities.first, diagnostic_code)
    end
  end
end
