# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckIn::V2::PatientCheckIn do
  subject { described_class }

  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    allow(Flipper).to receive(:enabled?)
      .with('check_in_experience_multiple_appointment_support').and_return(true)

    Rails.cache.clear
  end

  describe '.build' do
    it 'returns an instance of PatientCheckIn' do
      expect(subject.build({})).to be_an_instance_of(CheckIn::V2::PatientCheckIn)
    end
  end

  describe 'attributes' do
    it 'responds to check_in' do
      expect(subject.build({}).respond_to?(:check_in)).to be(true)
    end

    it 'responds to data' do
      expect(subject.build({}).respond_to?(:data)).to be(true)
    end

    it 'responds to settings' do
      expect(subject.build({}).respond_to?(:settings)).to be(true)
    end
  end

  describe '#unauthorized_message' do
    let(:uuid) { Faker::Internet.uuid }
    let(:check_in) { double('Session', uuid: uuid) }
    let(:data) { double('FaradayResponse', status: 200, body: {}) }
    let(:resp) { { permissions: 'read.none', status: 'success', uuid: uuid } }

    it 'returns a hashed response' do
      patient_check_in = subject.build(data: data, check_in: check_in)

      expect(patient_check_in.unauthorized_message).to eq(resp)
    end
  end

  describe '#error_status?' do
    let(:data) { double('FaradayResponse', status: 401, body: {}) }

    it 'returns true' do
      patient_check_in = subject.build(data: data, check_in: nil)

      expect(patient_check_in.error_status?).to eq(true)
    end
  end

  describe '#error_message' do
    let(:uuid) { Faker::Internet.uuid }
    let(:check_in) { double('Session', uuid: uuid) }
    let(:data) { double('FaradayResponse', status: 403, body: { error: 'forbidden' }.to_json) }
    let(:resp) { { error: true, message: { 'error' => 'forbidden' }, status: 403 } }

    it 'returns an error message' do
      patient_check_in = subject.build(data: data, check_in: nil)

      expect(patient_check_in.error_message).to eq(resp)
    end
  end
end
