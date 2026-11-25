require "test_helper"

class SuspensionCalendarTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  def after_teardown
    Capybara.current_session.driver.quit
    super
  end

  test "staff open the calendar from Suspended and browse ending dates on desktop and mobile" do
    # Use a future day early in a month so both calendar visits are independent of
    # the run date and session cookies won't be expired in the real browser.
    today = Date.current.next_month.beginning_of_month + 10.days
    current_expiry = today + 3.days
    following_expiry = today.next_month.beginning_of_month + 3.days
    current_patron = set_expiration(suspensions(:one), current_expiry, "Calendar Example With a Long Synthetic Surname")
    following_patron = set_expiration(suspensions(:two), following_expiry, "Next Month Example")
    suspended_list = patrons_list_path(suspended: true)
    call_911_list = patrons_list_path(suspended: true, call_911: true)

    travel_to Time.zone.local(today.year, today.month, today.day, 12) do
      with_google_auth(users(:one)) do
        set_viewport(1280, 900)
        visit patrons_list_path
        click_button "Sign in with Google"
        assert_current_path patrons_list_path

        within "nav[aria-label='Patron views']" do
          assert_link "Call 911", href: call_911_list
          click_button "Suspended"
          assert_selector "button[aria-expanded='true']", text: "Suspended"
          assert_link "Suspension List", href: suspended_list
          find_link("Suspension Calendar").send_keys(:escape)
          assert_no_link "Suspension List"
          assert_no_link "Suspension Calendar"
          assert_selector "button[aria-expanded='false']:focus", text: "Suspended"

          click_button "Suspended"
          click_link "Suspension Calendar"
        end

        assert_current_path patrons_suspension_calendar_path
        assert_selector "#suspension-month", text: current_expiry.strftime("%B %Y")
        assert_link "Call 911", href: call_911_list
        assert_no_link "Previous month"
        within ".suspension-month-grid [data-date='#{current_expiry.iso8601}']" do
          assert_selector "time[datetime='#{current_expiry.iso8601}']"
          assert_link current_patron.full_name, href: patrons_view_path(id: current_patron.id)
        end

        click_link "Next month"
        assert_current_path patrons_suspension_calendar_path(month: following_expiry.strftime("%Y-%m"))
        assert_selector "#suspension-month", text: following_expiry.strftime("%B %Y")
        within ".suspension-month-grid [data-date='#{following_expiry.iso8601}']" do
          assert_link following_patron.full_name, href: patrons_view_path(id: following_patron.id)
        end
        click_link "Previous month"
        assert_selector "#suspension-month", text: current_expiry.strftime("%B %Y")

        set_viewport(390, 844)
        assert_no_selector ".suspension-month-grid"
        within ".suspension-agenda [data-date='#{current_expiry.iso8601}']" do
          assert_selector "time[datetime='#{current_expiry.iso8601}']"
          assert_link current_patron.full_name, href: patrons_view_path(id: current_patron.id)
        end

        set_viewport(320, 700)
        assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth"),
          "The suspension calendar should fit a 320px viewport"
        within "nav[aria-label='Patron views']" do
          click_button "Suspended"
          assert_link "Suspension Calendar"
          assert page.evaluate_script(<<~JS), "The Suspended menu should fit a 320px viewport"
            (() => {
              const menu = document.querySelector(".section-navigation .dropdown-menu.show").getBoundingClientRect()
              return menu.left >= 0 && menu.right <= window.innerWidth
            })()
          JS
          find_link("Suspension Calendar").send_keys(:escape)
        end

        within ".suspension-agenda" do
          click_link current_patron.full_name
        end
        assert_current_path patrons_view_path(id: current_patron.id)
        assert_text current_patron.full_name
      end
    end
  end

  private

  def set_expiration(suspension, date, name)
    suspension.incident.update!(published: true, draft: false)
    suspension.update!(until: date)
    suspension.patron.tap do |patron|
      patron.update!(first_name: name, middle_name: nil, last_name: nil, known_as: nil)
    end
  end

  def set_viewport(width, height)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: width, height: height, deviceScaleFactor: 1, mobile: false)
    assert_equal [width, height], page.evaluate_script("[window.innerWidth, window.innerHeight]")
  end
end
