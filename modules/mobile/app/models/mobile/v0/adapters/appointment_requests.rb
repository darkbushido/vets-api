# frozen_string_literal: true

module Mobile
  module V0
    module Adapters
      class AppointmentRequests
        def parse(requests)
          # a bit unclear how to handle this
          # facilities = Set.new

          # replace with each with object
          requests.map do |request|
            status = status(request)
            next unless status

            build_appointment_model(request)
          end.compact
        end

        private

        def build_appointment_model(request)
          klass = request.key?(:cc_appointment_request) ? CC : VA

          Mobile::V0::Appointment.new(
            id: request[:appointment_request_id],
            appointment_type: klass::APPOINTMENT_TYPE,
            cancel_id: nil,
            comment: nil,
            facility_id: request.dig(:facility, :facility_code),
            sta6aid: nil,
            healthcare_provider: klass.provider_name(request),
            healthcare_service: klass.practice_name(request),
            location: klass.location(request),
            minutes_duration: nil,
            phone_only: phone_only?(request),
            start_date_local: nil,
            start_date_utc: start_date(request),
            status: status(request),
            status_detail: nil,
            time_zone: nil, # maybe base off of facility?
            vetext_id: nil,
            reason: request[:reason_for_visit],
            is_covid_vaccine: nil, # unable to find or create test data for this
            proposed_times: proposed_times(request),
            type_of_care: request[:appointment_type],
            visit_type: request[:visit_type],
            patient_phone_number: request[:phone_number],
            patient_email: request[:email],
            best_time_to_call: request[:best_timeto_call] # incoming data capitalizes incorrectly
          )
        end

        def phone_only?(request)
          return false if request[:text_messaging_allowed].nil?

          !request[:text_messaging_allowed]
        end

        def proposed_times(request)
          {
            option_date1: request[:option_date1],
            option_time1: request[:option_time1],
            option_date2: request[:option_date2],
            option_time2: request[:option_time2],
            option_date3: request[:option_date3],
            option_time3: request[:option_time3]
          }
        end

        def start_date(request)
          date = request[:option_date1]
          month, day, year = date.split('/').map(&:to_i)
          hour = request[:option_time1] == 'AM' ? 9 : 13

          DateTime.new(year, month, day, hour, 0)
        end

        def status(request)
          received_status = request[:status].upcase
          return received_status if received_status.in?(%w[CANCELLED SUBMITTED])

          nil
        end

        # needs:
        # facility address (handled separately i believe)
        # facility phone, also pulled from separate facility request
        # user's contact info: email, phone, preferred call time
        # timezone
        class VA
          APPOINTMENT_TYPE = 'VA_REQUEST'

          def self.provider_name(_)
            nil
          end

          def self.practice_name(_)
            nil
          end

          def self.location(request)
            facility_id = request.dig(:facility, :facility_code)
            facility = Mobile::VA_FACILITIES_BY_ID["dfn-#{facility_id}"]
            {
              id: facility_id,
              name: facility ? facility[:name] : nil,
              address: {
                street: nil,
                city: nil,
                state: nil,
                zip_code: nil
              },
              lat: nil,
              long: nil,
              phone: {
                area_code: nil,
                number: nil,
                extension: nil
              },
              url: nil,
              code: nil
            }
          end
        end

        # needs:
        # user's contact info
        class CC
          APPOINTMENT_TYPE = 'COMMUNITY_CARE_REQUEST'

          def self.provider_name(request)
            provider_section = request.dig(:cc_appointment_request, :preferred_providers, 0)
            if provider_section.nil? || (provider_section[:first_name].nil? && provider_section[:last_name].nil?)
              return nil
            end

            "#{provider_section[:first_name]} #{provider_section[:last_name]}".strip
          end

          def self.practice_name(request)
            request.dig(:cc_appointment_request, :preferred_providers, 0, :practice_name)
          end

          # should this be the facility or the cc data?
          def self.location(request)
            source = request[:cc_appointment_request]
            # captures area code \((\d{3})\) number (after space) \s(\d{3}-\d{4})
            # and extension (until the end of the string) (\S*)\z
            phone_captures = request[:phone_number].match(/\((\d{3})\)\s(\d{3}-\d{4})(\S*)\z/)
            {
              id: nil,
              name: practice_name(request),
              address: {
                street: source.dig(:preferred_providers, 0, :address),
                city: source[:preferred_city],
                state: source[:preferred_state],
                zip_code: source[:preferred_zip_code]
              },
              lat: nil,
              long: nil,
              phone: {
                area_code: phone_captures[1].presence,
                number: phone_captures[2].presence,
                extension: phone_captures[3].presence
              },
              url: nil,
              code: nil
            }
          end
        end
      end
    end
  end
end
