# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/iam_session_helper'
require_relative '../support/matchers/json_schema_matcher'

RSpec.describe 'appointments', type: :request do
  include JsonSchemaMatchers

  before do
    allow_any_instance_of(IAMUser).to receive(:icn).and_return('24811694708759028')
    iam_sign_in(build(:iam_user))
    allow_any_instance_of(VAOS::UserService).to receive(:session).and_return('stubbed_token')
  end

  before(:all) do
    @original_cassette_dir = VCR.configure(&:cassette_library_dir)
    VCR.configure { |c| c.cassette_library_dir = 'modules/mobile/spec/support/vcr_cassettes' }
  end

  after(:all) { VCR.configure { |c| c.cassette_library_dir = @original_cassette_dir } }

  describe 'PUT /mobile/v0/appointments/cancel' do
    context 'when request body params are missing' do
      let(:cancel_id) do
        'abc123'
      end

      it 'returns a 422 that lists all validation errors' do
        VCR.use_cassette('appointments/get_cancel_reasons', match_requests_on: %i[method uri]) do
          put "/mobile/v0/appointments/cancel/#{cancel_id}", headers: iam_headers

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to match_json_schema('errors')
          expect(response.parsed_body['errors'].size).to eq(1)
        end
      end
    end

    context 'with valid params' do
      let(:cancel_id) do
        Mobile::V0::Appointment.encode_cancel_id(
          start_date_local: DateTime.parse('2019-11-15T13:00:00'),
          clinic_id: '437',
          facility_id: '983',
          healthcare_service: 'CHY VISUAL FIELD'
        )
      end

      context 'when a valid cancel reason is not returned in the list' do
        it 'returns bad request with detail in errors' do
          VCR.use_cassette('appointments/get_cancel_reasons_invalid', match_requests_on: %i[method uri]) do
            put "/mobile/v0/appointments/cancel/#{cancel_id}", headers: iam_headers

            expect(response).to have_http_status(:not_found)
            expect(response.parsed_body['errors'].first['detail']).to eq(
              'This appointment can not be cancelled online because a prerequisite cancel reason could not be found'
            )
          end
        end
      end

      context 'when cancel reason returns a 500' do
        it 'returns bad request with detail in errors' do
          VCR.use_cassette('appointments/get_cancel_reasons_500', match_requests_on: %i[method uri]) do
            put "/mobile/v0/appointments/cancel/#{cancel_id}", headers: iam_headers
            expect(response).to have_http_status(:bad_gateway)
            expect(response.parsed_body['errors'].first['detail'])
              .to eq('Received an an invalid response from the upstream server')
          end
        end
      end

      context 'when a appointment cannot be cancelled online' do
        it 'returns bad request with detail in errors' do
          VCR.use_cassette('appointments/put_cancel_appointment_409', match_requests_on: %i[method uri]) do
            VCR.use_cassette('appointments/get_cancel_reasons', match_requests_on: %i[method uri]) do
              put "/mobile/v0/appointments/cancel/#{cancel_id}", headers: iam_headers

              expect(response).to have_http_status(:conflict)
              expect(response.parsed_body['errors'].first['detail'])
                .to eq('The facility does not support online scheduling or cancellation of appointments')
            end
          end
        end
      end
    end

    context 'when appointment can be cancelled' do
      let(:cancel_id) do
        Mobile::V0::Appointment.encode_cancel_id(
          start_date_local: DateTime.parse('2019-11-15T13:00:00'),
          clinic_id: '437',
          facility_id: '983',
          healthcare_service: 'CHY VISUAL FIELD'
        )
      end

      it 'cancels the appointment' do
        VCR.use_cassette('appointments/put_cancel_appointment', match_requests_on: %i[method uri]) do
          VCR.use_cassette('appointments/get_cancel_reasons', match_requests_on: %i[method uri]) do
            put "/mobile/v0/appointments/cancel/#{cancel_id}", headers: iam_headers
            expect(response).to have_http_status(:success)
            expect(response.body).to be_an_instance_of(String).and be_empty
          end
        end
      end

      it 'clears the cache after a succesful cancel' do
        VCR.use_cassette('appointments/put_cancel_appointment', match_requests_on: %i[method uri]) do
          VCR.use_cassette('appointments/get_cancel_reasons', match_requests_on: %i[method uri]) do
            expect(Mobile::V0::Appointment).to receive(:clear_cache).once

            put "/mobile/v0/appointments/cancel/#{cancel_id}", headers: iam_headers
          end
        end
      end

      context 'when appointment can be cancelled but fails' do
        let(:cancel_id) do
          Mobile::V0::Appointment.encode_cancel_id(
            start_date_local: DateTime.parse('2019-11-20T17:00:00'),
            clinic_id: '437',
            facility_id: '983',
            healthcare_service: 'CHY VISUAL FIELD'
          )
        end

        it 'raises a 502' do
          VCR.use_cassette('appointments/put_cancel_appointment_500', match_requests_on: %i[method uri]) do
            VCR.use_cassette('appointments/get_cancel_reasons', match_requests_on: %i[method uri]) do
              put "/mobile/v0/appointments/cancel/#{cancel_id}", headers: iam_headers

              expect(response).to have_http_status(:bad_gateway)
              expect(response.body).to match_json_schema('errors')
            end
          end
        end
      end
    end
  end
end
