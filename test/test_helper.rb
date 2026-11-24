ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  fixtures :all

  def with_env(values)
    original = ENV.to_h.slice(*values.keys)
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    values.each_key { |key| ENV[key] = original[key] }
  end

  def with_google_auth(user, domain: "example.org", verified: true, uid: user.uid)
    previous_mode = OmniAuth.config.test_mode
    previous_auth = OmniAuth.config.mock_auth[:google_oauth2]
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { name: user.name, email: user.email, email_verified: verified },
      extra: { raw_info: { hd: domain } }
    )

    with_env("AUTH_DOMAIN" => "example.org") { yield }
  ensure
    OmniAuth.config.test_mode = previous_mode
    OmniAuth.config.mock_auth[:google_oauth2] = previous_auth
  end
end

class ActionDispatch::IntegrationTest
  def sign_in(user)
    with_google_auth(user) { get "/auth/google_oauth2/callback" }
    assert_response :redirect
  end
end
