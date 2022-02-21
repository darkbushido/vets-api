# frozen_string_literal: true

require 'sentry_logging'

class Form526Submission < ApplicationRecord
  include SentryLogging
  include Form526Workflow

  # A 526 disability compensation form record. This class is used to persist the post transformation form
  # and track submission workflow steps.
  #
  # @!attribute id
  #   @return [Integer] auto-increment primary key.
  # @!attribute user_uuid
  #   @return [String] points to the user's uuid from the identity provider.
  # @!attribute saved_claim_id
  #   @return [Integer] the related saved claim id {SavedClaim::DisabilityCompensation}.
  # @!attribute auth_headers_json
  #   @return [String] encrypted EVSS auth headers as JSON {EVSS::DisabilityCompensationAuthHeaders}.
  # @!attribute form_json
  #   @return [String] encrypted form submission as JSON.
  # @!attribute workflow_complete
  #   @return [Boolean] are all the steps (jobs {EVSS::DisabilityCompensationForm::Job}) of the submission
  #     workflow complete.
  # @!attribute created_at
  #   @return [Timestamp] created at date.
  # @!attribute workflow_complete
  #   @return [Timestamp] updated at date.
  #
  has_kms_key
  encrypts :auth_headers_json, :birls_ids_tried, :form_json, key: :kms_key, **lockbox_options

  belongs_to :saved_claim,
             class_name: 'SavedClaim::DisabilityCompensation',
             inverse_of: false

  has_many :form526_job_statuses, dependent: :destroy

  validates(:auth_headers_json, presence: true)

  BIRLS_KEY = 'va_eauth_birlsfilenumber'

  def start
    if single_issue_hypertension_claim? && Flipper.enabled?(:disability_hypertension_compensation_fast_track)
      workflow_batch = Sidekiq::Batch.new
      workflow_batch.on(
        :success,
        'Form526Submission#start_evss_submission',
        'submission_id' => id
      )
      jids = workflow_batch.jobs do
        RapidReadyForDecision::DisabilityCompensationJob.perform_async(id, full_name)
      end
      jids.first
    else
      start_evss_submission(nil, { 'submission_id' => id })
    end
  rescue => e
    Rails.logger.error 'The fast track was skipped due to the following error ' \
                       " and start_evss_submission wass called: #{e}"
    start_evss_submission(nil, { 'submission_id' => id })
  end

  # Runs the start method above but first looks to see if the veteran has BIRLS IDs that previous start
  # attempts haven't used before (if so, swaps one of those into auth_headers).
  # If all BIRLS IDs for a veteran have been tried, does nothing and returns nil.
  # Note: this assumes that the current BIRLS ID has been used (that `start` has been attempted once).
  #
  # @return [String] the job id of the first job in the batch, i.e the 526 submit job
  # @return [NilClass] all BIRLS IDs for the veteran have been tried
  #
  def start_but_use_a_birls_id_that_hasnt_been_tried_yet!(
    extra_content_for_sentry: {},
    silence_errors_and_log_to_sentry: false
  )
    untried_birls_id = birls_ids_that_havent_been_tried_yet.first
    return unless untried_birls_id

    self.birls_id = untried_birls_id
    save!
    start
  rescue => e
    # 1) why have the 'silence_errors_and_log_to_sentry' option? (why not rethrow the error?)
    # This method is primarily intended to be triggered by a running Sidekiq job that has hit a dead end
    # (exhausted, or non-retryable error). One of the places this method is called is inside a
    # `sidekiq_retries_exhausted` block. It seems like the value of self for that block won't be the
    # Sidekiq job instance (so no access to the log_exception_to_sentry method). Also, rethrowing the error
    # (and letting it bubble up to Sidekiq) might trigger the current job to retry (which we don't want).
    raise unless silence_errors_and_log_to_sentry

    log_exception_to_sentry e, extra_content_for_sentry
  end

  def get_first_name
    user = User.find(user_uuid)
    user&.first_name&.upcase
  end

  # Checks against the User record first, and then resorts to checking the auth_headers
  # for the name attributes if the User record doesn't exist or contain the full name
  #
  # @return [Hash] of the user's full name (first, middle, last, suffix)
  #
  def full_name
    name_hash = User.find(user_uuid)&.full_name_normalized
    return name_hash if name_hash&.[](:first).present?

    {
      first: auth_headers&.dig('va_eauth_firstName')&.capitalize,
      middle: nil,
      last: auth_headers&.dig('va_eauth_lastName')&.capitalize,
      suffix: nil
    }
  end

  # @return [Hash] parsed version of the form json
  #
  def form
    @form_hash ||= JSON.parse(form_json)
  end

  # A 526 submission can include the 526 form submission, uploads, and ancillary items.
  # This method returns a single item as JSON
  #
  # @param item [String] the item key
  # @return [String] the requested form object as JSON
  #
  def form_to_json(item)
    form[item].to_json
  end

  # @return [Hash] parsed auth headers
  #
  def auth_headers
    @auth_headers_hash ||= JSON.parse(auth_headers_json)
  end

  # this method is for queuing up BIRLS ids in the birls_ids_tried hash,
  # and can also be used for initializing birls_ids_tried.
  # birls_ids_tried has this shape:
  # {
  #   birls_id => [timestamp, timestamp, ...],
  #   birls_id => [timestamp, timestamp, ...], # in practice, will be only 1 timestamp
  #   ...
  # }
  # where each timestamp notes when a submissison job (start) was started
  # with that BIRLS id (birls_id_tried keeps track of which BIRLS id
  # have been tried so far).
  # add_birls_ids does not overwrite birls_ids_tried.
  # example:
  # > sub.birls_ids_tried = { '111' => ['2021-01-01T0000Z'] }
  # > sub.add_birls_ids ['111', '222', '333']
  # > pp sub.birls_ids_tried
  #    {
  #      '111' => ['2021-01-01T0000Z'], # a tried BIRLS ID
  #      '222' => [],  # an untried BIRLS ID
  #      '333' => []   # an untried BIRLS ID
  #    }
  # NOTE: '111' was not cleared
  def add_birls_ids(id_or_ids)
    ids = Array.wrap(id_or_ids).map { |id| id.is_a?(Symbol) ? id.to_s : id }
    hash = birls_ids_tried_hash
    ids.each { |id| hash[id] ||= [] }
    self.birls_ids_tried = hash.to_json
    self.multiple_birls = true if birls_ids.length > 1
    ids
  end

  def birls_ids
    [*birls_ids_tried_hash&.keys, birls_id].compact.uniq
  end

  def birls_ids_tried_hash
    birls_ids_tried.presence&.then { |json| JSON.parse json } || {}
  end

  def mark_birls_id_as_tried(id = birls_id!, timestamp_string: Time.zone.now.iso8601.to_s)
    ids = add_birls_ids id
    hash = birls_ids_tried_hash
    hash[ids.first] << timestamp_string
    self.birls_ids_tried = hash.to_json
    timestamp_string
  end

  def mark_birls_id_as_tried!(*args, **kwargs)
    timestamp_string = mark_birls_id_as_tried(*args, **kwargs)
    save!
    timestamp_string
  end

  def birls_ids_that_havent_been_tried_yet
    add_birls_ids birls_id if birls_id.present?
    birls_ids_tried_hash.select { |_id, timestamps| timestamps.blank? }.keys
  end

  def birls_id!
    auth_headers[BIRLS_KEY]
  end

  def birls_id
    birls_id! if auth_headers_json
  end

  def birls_id=(value)
    headers = JSON.parse(auth_headers_json) || {}
    headers[BIRLS_KEY] = value
    self.auth_headers_json = headers.to_json
    @auth_headers_hash = nil # reset cache
  end

  class SubmitForm526JobStatusesError < StandardError; end

  def single_issue_hypertension_claim?
    disabilities = form.dig('form526', 'form526', 'disabilities')
    disabilities.count == 1 &&
      disabilities.first['disabilityActionType'] == 'INCREASE' &&
      disabilities.first['diagnosticCode'] == 7101
  end
end
