# frozen_string_literal: true

module RapidReadyForDecision
  class HypertensionSpecialIssueManager
    attr_accessor :submission

    def initialize(submission)
      @submission = submission
    end

    def add_special_issue
      submission_data = JSON.parse(submission.form_json, symbolize_names: true)
      disabilities = submission_data[:form526][:form526][:disabilities]
      disabilities.each do |disability|
        add_rrd_code(disability) if hypertension_increase?(disability)
      end
      submission.update!(form_json: JSON.dump(submission_data))
    end

    private

    HYPERTENSION_CODE = RapidReadyForDecision::DiagnosticCodes::HYPERTENSION
    RRD_CODE = 'RRD'

    def hypertension_increase?(disability)
      # Does the same as RapidReadyForDecision::ProcessorSelector.disability_increase?(disability, HYPERTENSION_CODE)
      # except using symbols as the keys instead of strings
      disability[:diagnosticCode] == HYPERTENSION_CODE &&
        disability[:disabilityActionType].downcase == 'increase'
    end

    # Must return an array containing special string codes for EVSS
    def add_rrd_code(disability)
      disability[:specialIssues] ||= []
      disability[:specialIssues].append(RRD_CODE) unless disability[:specialIssues].include?(RRD_CODE)
      disability
    end
  end
end
