# frozen_string_literal: true

require 'rails_helper'
require CovidResearch::Engine.root.join('spec', 'rails_helper.rb')
require_relative '../../../../app/workers/covid_research/volunteer/confirmation_mailer_job'

RSpec.describe CovidResearch::Volunteer::ConfirmationMailerJob do
  subject         { described_class.new }

  let(:recipient) { 'test@example.com' }
  let(:dummy)     { double('Mail::Message') }

  describe '#perform' do
    it 'builds an email to the given email' do
      allow(dummy).to receive(:deliver)
      allow(CovidResearch::Volunteer::SubmissionMailer).to receive(:build).with(recipient).and_return(dummy)

      subject.perform(recipient)
    end

    it 'delivers the email' do
      allow(CovidResearch::Volunteer::SubmissionMailer).to receive(:build).and_return(dummy)
      expect(dummy).to receive(:deliver)

      subject.perform(recipient)
    end
  end
end
