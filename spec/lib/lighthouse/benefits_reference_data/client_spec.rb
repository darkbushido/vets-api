# frozen_string_literal: true

require 'rails_helper'
require 'lighthouse/benefits_reference_data/client'

vcr_options = {
  cassette_name: '/lighthouse/benefits_reference_data/responses',
  match_requests_on: %i[path query],
  allow_playback_repeats: true,
  record: :new_episodes
}

RSpec.describe Lighthouse::BenefitsReferenceData::Client, team: :benefits_reference_data, vcr: vcr_options do
  let(:client) { Lighthouse::BenefitsReferenceData::Client.new }

  ## Get Countries
  #
  # Method:
  #   * GET
  #
  # Request URL:
  #   * https://sandbox-api.va.gov/services/benefits-reference-data/v1/countries
  #
  # Headers:
  #   * Authorizatio: Basic base64(<client_id>:<client_secret>)
  #   * apiKey: <redirectURL>
  #
  describe '#get_countries' do
    describe 'succes',
             vcr: vcr_options.merge(cassette_name: '/lighthouse/benefits_reference_data/get_countries_success') do
      let(:expected_keys) { %w[totalItems totalPages links items] }

      it 'returns a list of countries' do
        skip 'WIP'

        response = client.get_countries
        body = JSON.parse response.body
        keys = body.keys if respond_to? :keys
        items = body.items if respond_to? :items

        expect(response.status).to match 200
        expect(keys).to match_array expected_keys
        expect(items).to be_a Array
        expect(items).not_to be_empty
        expect(items.first).to be_a String
      end
    end

    # context 'with a bad API key', vcr: vcr_options.merge(cassette_name: '/lighthouse/facilities_401') do
    #   it 'returns a 401 error' do
    #   expect { facilities_client.get_by_id('vha_358') }
    #     .to raise_error do |e|
    #     expect(e).to be_a(Common::Exceptions::BackendServiceException)
    #     expect(e.status_code).to eq(401)
    #     expect(e.errors.first[:detail]).to eq('Invalid authentication credentials')
    #     expect(e.errors.first[:code]).to eq('LIGHTHOUSE_FACILITIES401')
    #   end
    # end
    describe 'failure' do
      describe 'Unauthorized',
               vcr: vcr_options.merge(cassette_name: '/lighthouse/benefits_reference_data/get_countries_401') do
        it 'returns status code 401' do
          response = client.get_countries
          status = response.status
          body = JSON.parse response.body

          expect(response.status).to match 401
          expect(body).to match 'message' => 'Invalid authentication credentials'
        end
      end
    end
  end

  ## Get States
  #
  # Method:
  #   * GET
  #
  # Request URL:
  #   * https://sandbox-api.va.gov/services/benefits-reference-data/v1/states
  #
  # Headers:
  #   * Authorizatio: Basic base64(<client_id>:<client_secret>)
  #   * apiKey: <redirectURL>
  #
  describe '#get_states' do
    describe 'succes'
    describe 'failure'
  end

  ## Get Separation Locations
  #
  # Method:
  #   * GET
  #
  # Request URL:
  #   * https://sandbox-api.va.gov/services/benefits-reference-data/v1/intake-sites
  #
  # Headers:
  #   * Authorizatio: Basic base64(<client_id>:<client_secret>)
  #   * apiKey: <redirectURL>
  #
  describe '#get_separation_locations' do
    describe 'succes'
    describe 'failure'
  end
end
