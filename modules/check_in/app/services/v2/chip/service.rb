# frozen_string_literal: true

module V2
  module Chip
    ##
    # A class to provide functionality related to CHIP service. This class needs to be instantiated
    # with a {CheckIn::V2::Session} object and check in parameters so that {Client} can be instantiated
    # appropriately.
    #
    # @!attribute [r] check_in
    #   @return [CheckIn::V2::Session]
    # @!attribute [r] response
    #   @return [V2::Chip::Response]
    # @!attribute [r] check_in_body
    #   @return [Hash]
    # @!attribute [r] chip_client
    #   @return [Client]
    # @!attribute [r] redis_client
    #   @return [RedisClient]
    # @!method client_error
    #   @return (see CheckIn::V2::Session#client_error)
    # @!method uuid
    #   @return (see CheckIn::V2::Session#uuid)
    # @!method valid?
    #   @return (see CheckIn::V2::Session#valid?)
    class Service
      extend Forwardable
      attr_reader :check_in, :response, :check_in_body, :chip_client, :redis_client

      def_delegators :check_in, :client_error, :uuid, :valid?

      ##
      # Builds a Service instance
      #
      # @param opts [Hash] options to create the object
      # @option opts [CheckIn::V2::Session] :check_in the session object
      # @option opts [Hash] :check_in_body check in request parameters
      #
      # @return [Service] an instance of this class
      #
      def self.build(opts = {})
        new(opts)
      end

      def initialize(opts = {})
        @check_in = opts[:check_in]
        @check_in_body = opts[:params]
        @response = Response

        @chip_client = Client.build(check_in_session: check_in)
        @redis_client = RedisClient.build
      end

      # Call the CHIP API to confirm that an appointment has been checked in. A CHIP token is required
      # and if it is either not present in Redis or cannot be retrieved from CHIP, an unauthorized
      # message is returned.
      #
      # @see https://github.com/department-of-veterans-affairs/chip CHIP API details
      #
      # @return [Hash] success message if successful
      # @return [Hash] unauthorized message if token is not present
      def create_check_in
        resp = if token.present?
                 chip_client.check_in_appointment(token: token, appointment_ien: check_in_body[:appointment_ien])
               else
                 Faraday::Response.new(body: check_in.unauthorized_message.to_json, status: 401)
               end

        response.build(response: resp).handle
      end

      # Call the CHIP API to refresh appointments. CHIP doesn't return refreshed appointments in the response
      # to this call, but rather updates LoROTA data as a result of this call. Code that uses this method
      # to refresh appointments should make use of {Lorota::Client#data} to retrieve refreshed data.
      #
      # @return [Faraday::Response] success message if successful
      # @return [Faraday::Response] unauthorized message if token is not present
      def refresh_appointments
        if token.present?
          chip_client.refresh_appointments(token: token, identifier_params: identifier_params)
        else
          Faraday::Response.new(body: check_in.unauthorized_message.to_json, status: 401)
        end
      end

      # Call the CHIP API to confirm pre-checkin status. A CHIP token is required
      # and if it is either not present in Redis or cannot be retrieved from CHIP, an unauthorized
      # message is returned.
      #
      # @see https://github.com/department-of-veterans-affairs/chip CHIP API details
      #
      # @return [Hash] success message if successful
      # @return [Hash] unauthorized message if token is not present
      def pre_check_in
        resp = if token.present?
                 chip_client.pre_check_in(token: token, demographic_confirmations: demographic_confirmations)
               else
                 Faraday::Response.new(body: check_in.unauthorized_message.to_json, status: 401)
               end

        response.build(response: resp).handle
      end

      # Get the CHIP token. If the token does not already exist in Redis, a call is made to CHIP token
      # endpoint to retrieve it.
      #
      # @see Chip::Client#token
      #
      # @return [String] token
      def token
        @token ||= begin
          token = redis_client.get

          return token if token.present?

          resp = chip_client.token

          Oj.load(resp.body)&.fetch('token').tap do |jwt_token|
            redis_client.save(token: jwt_token)
          end
        end
      end

      def identifier_params
        hashed_identifiers =
          Oj.load(appointment_identifiers).with_indifferent_access.dig(:data, :attributes)

        {
          patientDFN: hashed_identifiers[:patientDFN],
          stationNo: hashed_identifiers[:stationNo]
        }
      end

      def demographic_confirmations
        confirmed_at = Time.zone.now.iso8601

        result =
          {
            demographicConfirmations: {
              demographicsNeedsUpdate: check_in_body[:demographics_up_to_date] ? false : true,
              demographicsConfirmedAt: confirmed_at,
              nextOfKinNeedsUpdate: check_in_body[:next_of_kin_up_to_date] ? false : true,
              nextOfConfirmedAt: confirmed_at,
              emergencyContactNeedsUpdate: check_in_body[:emergency_contact_up_to_date] ? false : true,
              emergencyContactConfirmedAt: confirmed_at
            }
          }

        result.tap do |hash|
          if Flipper.enabled?(:check_in_experience_chip_service_nok_confirmation_update_enabled)
            hash[:demographicConfirmations].delete(:nextOfConfirmedAt)
            hash[:demographicConfirmations].store(:nextOfKinConfirmedAt, confirmed_at)
          end
        end
      end

      def appointment_identifiers
        Rails.cache.read(
          "check_in_lorota_v2_appointment_identifiers_#{check_in.uuid}",
          namespace: 'check-in-lorota-v2-cache'
        )
      end
    end
  end
end
