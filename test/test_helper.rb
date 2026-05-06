ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "omniauth"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionDispatch::IntegrationTest
  setup do
    ENV["AUTH_DOMAIN"] = "tadl.org"
    ENV["CAN_EDIT"] = ""
    ENV["CAN_SUSPEND"] = ""
    ENV["SUPER_ADMIN"] = ""
  end

  def sign_in_as(user)
    post "/test/sign_in/#{user.id}"
  end

  def create_user(email: "staff@tadl.org")
    User.create!(
      provider: "google_oauth2",
      uid: "uid-#{SecureRandom.hex(4)}",
      name: "Staff User",
      email: email,
      oauth_token: "token",
      oauth_expires_at: 1.hour.from_now
    )
  end

  def create_incident(created_by:, title: "Incident #{SecureRandom.hex(4)}", published: true, draft: false)
    Incident.create!(
      title: title,
      description: "Description #{SecureRandom.hex(4)}",
      location: "Main Library",
      date_of: Time.zone.local(2026, 5, 1, 12, 0),
      created_by: created_by.id.to_s,
      last_edit_by: created_by.id.to_s,
      published: published,
      draft: draft,
      published_on: (Time.current if published),
      violation_format: "summary"
    )
  end

  def create_patron
    Patron.create!(first_name: "Pat", last_name: "Ron")
  end
end
