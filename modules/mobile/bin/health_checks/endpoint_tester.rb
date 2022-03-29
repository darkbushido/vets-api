# frozen_string_literal: true

require 'colorize'
require 'thor'
require 'yaml'
require_relative 'token_fetcher'
require_relative 'client'

class EndpointTester < Thor
  TEST_DATA_DIR = File.join(File.dirname(__FILE__), 'request_data')

  desc 'run tests', 'tests endpoints based on yaml inputs'
  option :base_url
  option :test_name
  def run_tests
    @users = {}
    @results = {}
    files = Dir["#{TEST_DATA_DIR}/**/*.yaml"]
    files.each do |f|
      test_data = YAML.safe_load(File.read(f))
      sequence = test_data['sequence']
      sequence.each do |test_case|
        test_data = test_case['case']
        next if options[:test_name] && test_data['name'] != options[:test_name]

        run_individual_test_case(test_data)
      end
    end
    process_results
  end

  private

  def run_individual_test_case(data)
    method = data['method']
    path = data['request']['path']
    user_name = data['request']['user']
    client = client(user_name)

    response = case method
               when 'GET'
                 client.get(path)
               else
                 abort("Invalid method: #{method}".red)
               end

    validate_response(data, response)
  end

  def validate_response(expected_data, response)
    test_name = expected_data['name']
    @results[test_name] = []
    @current_test = @results[test_name]

    expected_status = expected_data.dig('response', 'status')
    correct_status_received = expected_status == response.status

    if correct_status_received
      received_data = JSON.parse(response.body)

      count = expected_data.dig('response', 'count')
      add_error('count', count, received_data['data'].count) if count && count != received_data['data'].count

      expected_data = expected_data.dig('response', 'body')
      compare_data(expected_data, received_data) if expected_data
    else
      add_error('status', expected_status, response.status)
    end

    @results[test_name].empty? ? print('.'.green) : print('.'.red)
  end

  def compare_data(expected, received)
    expected.each do |k, v|
      case v
      when Hash
        compare_data(v, received[k])
      when Array
        v.each_with_index do |array_item, i|
          compare_data(array_item, received[k][i])
        end
      else
        add_error(k, v, received[k]) unless v == received[k]
      end
    end
  end

  def add_error(descriptor, expected, received)
    @current_test << "#{descriptor}: expected #{expected}, received #{received}"
  end

  def process_results
    successes, failures = @results.partition { |_, v| v.empty? }

    puts
    puts "Successful tests: #{successes.count}".green
    if failures.any?
      puts "Failed tests: #{failures.count}".red
      failures.each do |name, messages|
        puts "Test #{name} failed with errors:".red
        messages.each { |message| puts "\t#{message.red}" }
      end
      abort
    end
    puts 'All tests passing'.green
  end

  def client(user_name)
    return @users[user_name] if @users[user_name]

    token = user_token(user_name)
    client = Client.new(token, options[:base_url])
    @users[user_name] = client
    client
  end

  def user_token(user_name)
    fetcher = TokenFetcher.new(user_name)
    fetcher.fetch_token
    fetcher.token
  end
end

EndpointTester.start(ARGV)
