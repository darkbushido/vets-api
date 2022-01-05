# frozen_string_literal: true

require 'rails_helper'
require 'saml/ssoe_settings_service'
require 'lib/sentry_logging_spec_helper'

RSpec.describe SAML::SSOeSettingsService do
  before do
    Settings.saml_ssoe.idp_metadata_file = Rails.root.join('spec', 'support', 'saml', 'test_idp_metadata.xml')
    Settings.saml_ssoe.idp_metadata_url = 'https://int.eauth.va.gov/isam/saml/metadata/saml20idp'
    Settings.saml_ssoe.va_identity_alerts_webhook = 'https://hooks.slack.com/services/asdf1234'
    Settings.vsp_environment = 'development'
  end

  describe '.saml_settings' do
    it 'returns a settings instance' do
      expect(SAML::SSOeSettingsService.saml_settings).to be_an_instance_of(OneLogin::RubySaml::Settings)
    end

    it 'allows override of provided settings' do
      settings = SAML::SSOeSettingsService.saml_settings('sp_entity_id' => 'testIssuer')
      expect(settings.sp_entity_id).to equal('testIssuer')
    end

    context 'with no signing or encryption configured' do
      it 'omits certificate from settings' do
        with_settings(Settings.saml_ssoe, certificate: 'foobar',
                      request_signing: false, response_signing: false, response_encryption: false) do
          expect(SAML::SSOeSettingsService.saml_settings.certificate).to be_nil
        end
      end
    end

    context 'with signing configured' do
      it 'includes certificate in settings' do
        with_settings(Settings.saml_ssoe, certificate: 'foobar',
                                          request_signing: true, response_signing: false,
                                          response_encryption: false) do
          expect(SAML::SSOeSettingsService.saml_settings.certificate).to eq('foobar')
        end
      end
    end

    context 'with encryption configured' do
      it 'includes certificate in settings' do
        with_settings(Settings.saml_ssoe, certificate: 'foobar',
                                          request_signing: false, response_signing: false,
                                          response_encryption: true) do
          expect(SAML::SSOeSettingsService.saml_settings.certificate).to eq('foobar')
        end
      end
    end
  end

  describe '.parse_idp_metadata' do
    context 'match between file & url metadata' do
      it 'returns parsed metadata from file' do
        VCR.use_cassette('saml/idp_int_metadata_isam', match_requests_on: %i[path query]) do
          allow_any_instance_of(OneLogin::RubySaml::IdpMetadataParser).to receive(:parse)
            .with(File.read(Settings.saml_ssoe.idp_metadata_file))
          expect_any_instance_of(OneLogin::RubySaml::IdpMetadataParser).to receive(:parse)
          SAML::SSOeSettingsService.parse_idp_metadata
        end
      end
    end

    context 'mismatch between file & url metadata' do
      it 'returns parsed metadata from url' do
        VCR.use_cassette('saml/updated_idp_int_metadata_isam',
                         allow_playback_repeats: true,
                         match_requests_on: %i[path query]) do
          VCR.use_cassette('slack/slack_bot_notify', match_requests_on: %i[path query]) do
            allow_any_instance_of(OneLogin::RubySaml::IdpMetadataParser).to receive(:parse_remote)
              .with(Settings.saml_ssoe.idp_metadata_url)
            expect_any_instance_of(OneLogin::RubySaml::IdpMetadataParser).to receive(:parse_remote)
            SAML::SSOeSettingsService.parse_idp_metadata
          end
        end
      end

      it 'notifies the #vsp-identity channel on Slack' do
        VCR.use_cassette('saml/updated_idp_int_metadata_isam',
                         allow_playback_repeats: true,
                         match_requests_on: %i[path query]) do
          VCR.use_cassette('slack/slack_bot_notify', match_requests_on: %i[path query]) do
            allow_any_instance_of(Slack::Service).to receive(:notify)
            expect_any_instance_of(Slack::Service).to receive(:notify)
            SAML::SSOeSettingsService.parse_idp_metadata
          end
        end
      end
    end
  end
end
