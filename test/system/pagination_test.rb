require "test_helper"

class PaginationTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  def after_teardown
    Capybara.current_session.driver.quit
    super
  end

  test "staff can jump between pages on narrow browse and search views" do
    query = "synthetic pagination"
    Oldreport.insert_all!(Array.new(85) do |index|
      { legacy_id: "PAGER-#{index}", title: "Example record #{index}",
        description: query, date_of: Date.new(2025, 1, 1) + index }
    end)
    Incident.insert_all!(Array.new(790) do |index|
      { title: "Example incident #{index}", description: query, location: "Woodmere",
        date_of: Time.zone.local(2025, 1, 1) + index.hours, published: true, draft: false }
    end)

    with_google_auth(users(:one)) do
      visit incidents_path(page: 38)
      click_button "Sign in with Google"
      assert_current_path incidents_path(page: 38)
      set_viewport(1280, 900)
      assert_selector ".list-toolbar nav[aria-label='Incident views']"
      assert_selector ".list-toolbar nav[aria-label='Result pages at top']"
      assert page.evaluate_script(<<~JS), "The desktop pager should be beside the incident filters"
        (() => {
          const tabs = document.querySelector(".list-toolbar .section-navigation").getBoundingClientRect()
          const pager = document.querySelector(".list-toolbar .list-pagination").getBoundingClientRect()
          return pager.left >= tabs.right && pager.top < tabs.bottom && tabs.top < pager.bottom
        })()
      JS
      set_viewport(390, 844)
      assert_equal 390, page.evaluate_script("window.innerWidth")
      assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")

      visit old_list_path
      within "nav[aria-label='Result pages at top']" do
        assert_equal %w[1 2 3 … 7 8 9], all("[aria-current='page'], [aria-label^='Page '], .pagination-gap").map(&:text)
        find("a[aria-label='Last page']").click
      end
      assert_current_path old_list_path(page: 9)
      within "nav[aria-label='Result pages at bottom']" do
        assert_selector "[aria-current='page']", text: "9"
        assert_selector "[aria-label='Next page'][aria-disabled='true']"
        find("a[aria-label='First page']").click
      end
      assert_current_path old_list_path(page: 1)

      visit old_search_path
      within "form[action='#{old_search_path}']" do
        find("input[name='query']").set(query)
        click_button "Search"
      end
      within "nav[aria-label='Search result pages at bottom']" do
        assert_equal %w[1 2 3 … 7 8 9], all("[aria-current='page'], [aria-label^='Page '], .pagination-gap").map(&:text)
        find("button[aria-label='Last page']").click
      end
      assert_current_path old_search_path
      assert_selector "article.record-card", count: 5
      assert_selector "nav.search-pagination [aria-current='page']", text: "9", count: 2
    end
  end

  private

  def set_viewport(width, height)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: width, height: height, deviceScaleFactor: 1, mobile: false)
  end
end
