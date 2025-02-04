# frozen_string_literal: true

FactoryBot.define do
  factory :session_container, class: 'SignIn::SessionContainer' do
    skip_create

    session { create(:oauth_session) }
    refresh_token { create(:refresh_token) }
    access_token { create(:access_token) }
    anti_csrf_token { SecureRandom.hex }

    initialize_with do
      new(session: session,
          refresh_token: refresh_token,
          access_token: access_token,
          anti_csrf_token: anti_csrf_token)
    end
  end
end
