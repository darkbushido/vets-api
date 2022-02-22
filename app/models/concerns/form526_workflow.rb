# frozen_string_literal: true

module Form526Workflow
  extend ActiveSupport::Concern

  FORM_526 = 'form526'
  FORM_526_UPLOADS = 'form526_uploads'
  FORM_4142 = 'form4142'
  FORM_0781 = 'form0781'
  FORM_8940 = 'form8940'
  FLASHES = 'flashes'
  SUBMIT_FORM_526_JOB_CLASSES = %w[SubmitForm526AllClaim SubmitForm526].freeze

  # Kicks off a 526 submit workflow batch. The first step in a submission workflow is to submit
  # an increase only or all claims form. Once the first job succeeds the batch will callback and run
  # one (cleanup job) or more ancillary jobs such as uploading supporting evidence or submitting ancillary forms.
  #
  # @return [String] the job id of the first job in the batch, i.e the 526 submit job
  #
  def self.start_evss_submission(_status, options)
    submission = Form526Submission.find(options['submission_id'])
    workflow_batch = Sidekiq::Batch.new
    workflow_batch.on(
      :success,
      'BatchDoneHandlers#perform_ancillary_jobs_handler',
      'submission_id' => submission.id
    )
    jids = workflow_batch.jobs do
      EVSS::DisabilityCompensationForm::SubmitForm526AllClaim.perform_async(submission.id)
    end

    jids.first
  end

  class BatchDoneHandlers
    # The workflow batch success handler
    #
    # @param _status [Sidekiq::Batch::Status] the status of the batch
    # @param options [Hash] payload set in the workflow batch
    #
    def perform_ancillary_jobs_handler(_status, options)
      submission = Form526Submission.find(options['submission_id'])
      # Only run ancillary jobs if submission succeeded
      submission.perform_ancillary_jobs(submission.get_first_name) if submission.jobs_succeeded?
    end

    # Checks if all workflow steps were successful and if so marks it as complete.
    #
    # @param _status [Sidekiq::Batch::Status] the status of the batch
    # @param options [Hash] payload set in the workflow batch
    #
    def workflow_complete_handler(_status, options)
      submission = Form526Submission.find(options['submission_id'])
      if submission.jobs_succeeded?
        submission.send_form526_confirmation_email(options['first_name'])
        submission.workflow_complete = true
        submission.save
      else
        submission.send_form526_submission_failed_email(options['first_name'])
      end
    end
  end

  def jobs_succeeded?
    a_submit_form_526_job_succeeded? && all_other_jobs_succeeded_if_any?
  end

  def a_submit_form_526_job_succeeded?
    submit_form_526_job_statuses = form526_job_statuses.where(job_class: SUBMIT_FORM_526_JOB_CLASSES).order(:updated_at)
    submit_form_526_job_statuses.presence&.any?(&:success?)
  ensure
    successful = submit_form_526_job_statuses.where(status: 'success').load
    warn = ->(message) { log_message_to_sentry(message, :warn, { form_526_submission_id: id }) }
    warn.call 'There are multiple successful SubmitForm526 job statuses' if successful.size > 1
    if successful.size == 1 && submit_form_526_job_statuses.last.unsuccessful?
      warn.call "There is a successful SubmitForm526 job, but it's not the most recent SubmitForm526 job"
    end
  end

  # Creates a batch for the ancillary jobs, sets up the callback, and adds the jobs to the batch if necessary
  #
  # @param first_name [String] the first name of the user that submitted Form526
  # @return [String] the workflow batch id
  #
  def perform_ancillary_jobs(first_name)
    workflow_batch = Sidekiq::Batch.new
    workflow_batch.on(
      :success,
      'BatchDoneHandlers#workflow_complete_handler',
      'submission_id' => id,
      'first_name' => first_name
    )
    workflow_batch.jobs do
      submit_uploads if form[FORM_526_UPLOADS].present?
      submit_form_4142 if form[FORM_4142].present?
      submit_form_0781 if form[FORM_0781].present?
      submit_form_8940 if form[FORM_8940].present?
      upload_bdd_instructions if bdd?
      submit_flashes if form[FLASHES].present?
      cleanup
    end
  end

  def bdd?
    form.dig('form526', 'form526', 'bddQualified') || false
  end

  def send_form526_confirmation_email(first_name)
    email_address = form['form526']['form526']['veteran']['emailAddress']
    personalization_parameters = {
      'email' => email_address,
      'submitted_claim_id' => submitted_claim_id,
      'date_submitted' => created_at.strftime('%B %-d, %Y %-l:%M %P %Z').sub(/([ap])m/, '\1.m.'),
      'first_name' => first_name
    }
    Form526ConfirmationEmailJob.perform_async(personalization_parameters)
  end

  def send_form526_submission_failed_email(first_name)
    email_address = form['form526']['form526']['veteran']['emailAddress']
    personalization_parameters = {
      'email' => email_address,
      'submitted_claim_id' => submitted_claim_id,
      'date_submitted' => created_at.strftime('%B %-d, %Y %-l:%M %P %Z').sub(/([ap])m/, '\1.m.'),
      'first_name' => first_name
    }
    Form526SubmissionFailedEmailJob.perform_async(personalization_parameters)
  end

  private

  def all_other_jobs_succeeded_if_any?
    form526_job_statuses.where.not(job_class: SUBMIT_FORM_526_JOB_CLASSES).all?(&:success?)
  end

  def submit_uploads
    # Put uploads on a one minute delay because of shared workload with EVSS
    uploads = form[FORM_526_UPLOADS]
    delay = 60.seconds
    uploads.each do |upload|
      EVSS::DisabilityCompensationForm::SubmitUploads.perform_in(delay, id, upload)
      delay += 15.seconds
    end
  end

  def upload_bdd_instructions
    # send BDD instructions
    EVSS::DisabilityCompensationForm::UploadBddInstructions.perform_in(60.seconds, id)
  end

  def submit_form_4142
    CentralMail::SubmitForm4142Job.perform_async(id)
  end

  def submit_form_0781
    EVSS::DisabilityCompensationForm::SubmitForm0781.perform_async(id)
  end

  def submit_form_8940
    EVSS::DisabilityCompensationForm::SubmitForm8940.perform_async(id)
  end

  def submit_flashes
    user = User.find(user_uuid)
    BGS::FlashUpdater.perform_async(id) if user && Flipper.enabled?(:disability_compensation_flashes, user)
  end

  def cleanup
    EVSS::DisabilityCompensationForm::SubmitForm526Cleanup.perform_async(id)
  end
end
