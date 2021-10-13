require "rails_helper"

if ENV['LOGIN_SYSTEM_TESTS']
  RSpec.describe 'ID.me login', type: :system do
    before do
      driven_by :selenium_chrome
      Capybara.server = :puma
      Capybara.app_host = 'https://staging.va.gov'
      Capybara.run_server = false # don't start Rack
      Capybara.default_max_wait_time = 8
      VCR.turn_off!
    end

    it 'can log in an LOA1 user' do
      visit '/'
      click_button 'Sign in'
      click_button 'Sign in with ID.me'
      fill_in 'Email', with: ENV['EMAIL']
      fill_in 'Password', with: ENV['PASSWORD']
      click_button 'Sign in to ID.me'
      click_button 'Continue'
      click_button 'Continue'
    end
  end
end
