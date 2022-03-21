# frozen_string_literal: true

require 'rails_helper'
require 'mpi/orch_search_service'

describe MPI::OrchSearchService do
  let(:user) { build(:user, :loa3, user_hash) }
  let(:user_hash) do
    {
      first_name: 'MARK',
      last_name: 'WEBB',
      middle_name: '',
      birth_date: '1950-10-04',
      ssn: '796104437',
      edipi: '1013590059'
    }
  end
  let(:server_error) { MPI::Responses::FindProfileResponse::RESPONSE_STATUS[:server_error] }

  describe '.find_profile with attributes' do
    context 'valid request to MPI' do
      it 'calls the find profile with an orchestrated search', run_at: 'Thu, 06 Feb 2020 23:59:36 GMT' do
        allow(SecureRandom).to receive(:uuid).and_return('b4d9a901-8f2f-46c0-802f-3eeb99c51dfb')
        allow(Socket).to receive(:ip_address_list).and_return([Addrinfo.ip('1.1.1.1')])

        VCR.use_cassette('mpi/find_candidate/orch_search_with_attributes', VCR::MATCH_EVERYTHING) do
          Settings.mvi.vba_orchestration = true
          response = described_class.new.find_profile(user)
          expect(response.status).to eq('OK')
          expect(response.profile.icn).to eq('1008709396V637156')
          Settings.mvi.vba_orchestration = false
        end
      end
    end

    context 'context invalid request to MPI' do
      it 'raises a invalid request error', :aggregate_failures do
        invalid_xml = File.read('spec/support/mpi/find_candidate_invalid_request.xml')
        allow_any_instance_of(MPI::Service).to receive(:create_profile_message).and_return(invalid_xml)
        expect(subject).to receive(:log_exception_to_sentry)

        VCR.use_cassette('mpi/find_candidate/invalid') do
          response = subject.find_profile(user)
          exception = response.error.errors.first
          expect(response.status).to eq server_error
          expect(response.profile).to be_nil
          expect(exception.status).to eq '502'
        end
      end
    end
  end
end
