require "test_helper"

class StaffWorkflowTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  # Restart the clean browser session between tests. Chrome rejects the
  # wildcard storage origin used by Capybara's automatic reset.
  def after_teardown
    Capybara.current_session.driver.quit
    super
  end

  test "staff can sign in, publish a draft and post extra information" do
    previous_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    with_google_auth(users(:one)) do
      visit incidents_new_path
      click_button "Sign in with Google"
      assert_current_path incidents_new_path

      fill_in "Title", with: "Synthetic browser workflow"
      select "Woodmere", from: "Location"
      fill_in "Description", with: "A synthetic browser test report."
      click_button "Save as draft"

      assert_text "Draft"
      assert_text "Synthetic browser workflow"
      click_link "Edit incident"
      click_button "Publish incident"
      assert_current_path %r{\A/incidents/view\?id=\d+\z}

      fill_in "Add extra information", with: "Synthetic follow-up"
      click_button "Save extra information"
      assert_text "Synthetic follow-up"

      click_button "Sign out"
      assert_current_path sign_in_path
    end
  ensure
    ActionController::Base.allow_forgery_protection = previous_forgery_protection
  end
end
