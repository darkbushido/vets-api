# frozen_string_literal: true

# require './spec/lib/webhooks/utilities_helper'
require 'rails_helper'
require './lib/webhooks/utilities'

RSpec.describe 'Webhooks::Utilities' do
  let(:websocket_settings) do
    {
        require_https: false
    }
  end

  let(:dev_headers) do
    {
        'X-Consumer-ID': '59ac8ab0-1f28-43bd-8099-23adb561815d',
        'X-Consumer-Username': 'Development'
    }
  end
  let(:webhook) do
    {
        'callbacks' => [
            {
                'event' => 'test_event',
                'urls' => [
                    'https://i/am/listening',
                    'https://i/am/also/listening'
                ]
            }
        ]
    }
  end
  let(:maintenance) do
    {
      'api_name' => 'TEST_API',
      'urls'=> [
        {
          'url'=> 'https://i/am/listening',
          'maintenance'=> true
        },
        {
          'url'=> 'https://i/am/also/listening',
          'maintenance'=> false
        }
      ]
    }
  end

  let(:maint_fixture_path) { './spec/fixtures/webhooks/maintenance/' }
  let(:subscription_fixture_path) { './spec/fixtures/webhooks/subscriptions/' }

  before(:all) do
    class TestHelper
      include Webhooks::Utilities
    end

    Webhooks::Utilities.register_events('test_event',
                                        api_name: 'TEST_API', max_retries: 3) do
      'working!'
    end
    Webhooks::Utilities.register_events('test_event_multiple_APIs',
                                        api_name: 'TEST_API_multiple_APIs', max_retries: 3) do
      'working!'
    end
  end

  before do
    Settings.websockets = Config::Options.new
    websocket_settings.each_pair do |k, v|
      Settings.websockets.send("#{k}=".to_sym, v)
    end
  end

  it 'requires max_retries to be greater than zero' do
    expect do
      Webhooks::Utilities.register_events('test_event_max_retries',
                                          api_name: 'TEST_API_max_retries', max_retries: -1) do
        'working!'
      end
    end.to raise_error do |e|
      expect(e.message).to match(/^max_retries argument must be greater than zero/i)
    end
  end

  it 'registers events and blocks' do
    module Testing
      include Webhooks::Utilities
      EVENTS = %w[event1 event2 event3].freeze
      register_events(*EVENTS,
                      api_name: 'TEST_API2', max_retries: 3) do
        'working!'
      end
    end
    # total_events = Testing::EVENTS.length + 1
    # initial registration in before block adds one
    # expect(Webhooks::Utilities.supported_events.length).to be(total_events)
    # Above test on the build server gets hard to do if another tests causes a registration.  We check each event...
    Testing::EVENTS.each do |e|
      expect(Webhooks::Utilities.supported_events.include?(e)).to be true
      expect(Webhooks::Utilities.event_to_api_name[e]).to be 'TEST_API2'
    end
    expect(Webhooks::Utilities.api_name_to_time_block['TEST_API2'].call).to be 'working!'
    expect(Webhooks::Utilities.api_name_to_retries['TEST_API2']).to be 3
  end

  it 'does not allow over registration' do
    event_spans_api = lambda do
      Webhooks::Utilities.register_events('test_event', api_name: 'OTHER_API', max_retries: 3) do
        'working!'
      end
    end
    api_duplicated = lambda do
      Webhooks::Utilities.register_events('other_event', api_name: 'TEST_API', max_retries: 3) do
        'working!'
      end
    end
    expect do
      event_spans_api.call
    end.to raise_error(ArgumentError)
    expect do
      api_duplicated.call
    end.to raise_error(ArgumentError)
  end

  # assumes subscription has been validated
  it 'fetches all events from a subscription' do
    events = Webhooks::Utilities.fetch_events(webhook)
    expect(events.length).to be 1
    expect(events.include?('test_event')).to be true
  end

  it 'allows valid subscriptions' do
    subscription = TestHelper.new.validate_subscription(webhook)
    expect(subscription).to be webhook
  end

  it 'does not allow invalid subscriptions' do
    expect do
      TestHelper.new.validate_subscription({ invalid: :stuff })
    end.to raise_error(StandardError)
  end

  # rubocop:disable Style/MultilineBlockChain
  it 'detects invalid events' do
    webhook['callbacks'].first['event'] = 'bad_event'
    expect do
      TestHelper.new.validate_events(webhook['callbacks'])
    end.to raise_error do |e|
      expect(e.errors.first.detail).to match(/^invalid/i)
    end
  end

  it 'detects events spanning multiple APIs' do
    webhook['calllks'] << webhook['caallbacks'].first.deep_dup
    webhook['callbacks'].last['event'] = 'test_event_multiple_APIs'
    expect do
      TestHelper.new.validate_events(webhook['callbacks'])
    end.to raise_error do |e|
      expect(e.errors.first.detail).to match(/^Subscription cannot span multiple APIs/i)
    end
  end

  it 'detects duplicate events' do
    duplicate = webhook['callbacks'].first.deep_dup
    webhook['callbacks'] << duplicate
    expect do
      TestHelper.new.validate_events(webhook['callbacks'])
    end.to raise_error do |e|
      expect(e.errors.first.detail).to match(/^duplicate/i)
    end
  end

  it 'validates urls' do
    with_settings(Settings.webhooks, require_https: false) do
      expect(TestHelper.new.validate_url('http://www.google.com')).to be true
    end
    expect do
      TestHelper.new.validate_url('Not a good url')
    end.to raise_error do |e|
      expect(e.errors.first.detail).to match(/URI does not parse/)
    end
    with_settings(Settings.webhooks, require_https: true) do
      expect(TestHelper.new.validate_url('https://www.google.com')).to be true
      expect do
        TestHelper.new.validate_url('http://www.google.com')
      end.to raise_error do |e|
        expect(e.errors.first.detail).to match(/must be https/)
      end
    end
    with_settings(Settings.webhooks, require_https: false) do
      valids = ['http://www.google.com', 'https://www.google.com']
      expect(TestHelper.new.validate_urls(valids)).to be true
    end
  end

  it 'allows valid maintenance objects' do
    Webhooks::Utilities.register_webhook(dev_headers[:'X-Consumer-ID'],
                                         dev_headers[:'X-Consumer-Username'],
                                         webhook)
    maint = TestHelper.new.validate_maintenance(maintenance, dev_headers[:'X-Consumer-ID'])
    expect(maint).to be maintenance
  end

  it 'does not allow invalid maintenance objects' do
    expect do
      TestHelper.new.validate_maintenance({ invalid: :stuff }, dev_headers[:'X-Consumer-ID'])
    end.to raise_error(StandardError)
  end

  it 'detects invalid api names' do
    Webhooks::Utilities.register_webhook(dev_headers[:'X-Consumer-ID'],
                                         dev_headers[:'X-Consumer-Username'],
                                         webhook)
    maintenance['api_name'] = 'bad_api_name'
    expect do
      TestHelper.new.validate_maintenance(maintenance, dev_headers[:'X-Consumer-ID'])
    end.to raise_error do |e|
      expect(e.errors.first.detail).to match(/^invalid/i)
    end
  end

  it 'detects invalid webhook urls through validate_maintenance' do
    Webhooks::Utilities.register_webhook(dev_headers[:'X-Consumer-ID'],
                                         dev_headers[:'X-Consumer-Username'],
                                         webhook)
    maintenance['urls'].first['url'] = 'https://bad-url.net'
    expect do
      TestHelper.new.validate_maintenance(maintenance, dev_headers[:'X-Consumer-ID'])
    end.to raise_error do |e|
      expect(e.errors.first.detail).to match(/URL is not subscribed to the given api_name/i)
    end
  end

  it 'detects webhook urls that aren\'t subscribed' do
    Webhooks::Utilities.register_webhook(dev_headers[:'X-Consumer-ID'],
                                         dev_headers[:'X-Consumer-Username'],
                                         webhook)
    url = 'https://bad-url.net'
    expect do
      TestHelper.new.url_subscribed?(url,
                                     dev_headers[:'X-Consumer-ID'],
                                     Webhooks::Utilities.event_to_api_name[webhook['callbacks'].first['event']])
    end.to raise_error do |e|
      expect(e.errors.first.detail).to match(/URL is not subscribed to the given api_name/i)
    end
  end

  it 'detects if maintenance is trying to update a subscription that doesn\'t exist for the given api' do
    maintenance['urls'].first['url'] = 'https://bad-url.net'
    expect do
      TestHelper.new.validate_maintenance(maintenance, dev_headers[:'X-Consumer-ID'])
    end.to raise_error do |e|
      expect(e.errors.first.detail).to match(/^Subscription for the given api_name does not exist!/i)
    end
  end
  # rubocop:enable Style/MultilineBlockChain
end
