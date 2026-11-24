require "test_helper"

class StaffNavigationTest < ActionDispatch::IntegrationTest
  test "staff navigation preserves the current incident view and offers a POST sign-out" do
    sign_in users(:one)

    get incidents_path(just_drafts: true)

    assert_response :success
    assert_select "header nav[aria-label='Main navigation'] a[aria-current='location']", text: "Incidents"
    assert_select "main nav[aria-label='Incident views'] a[aria-current='page']", text: "My drafts"
    assert_select "header form[method='post'][action=?]", signout_path
    assert_select "header a[href=?]", incidents_new_path
  end

  test "legacy search pagination resubmits the search in a POST body" do
    sign_in users(:one)
    query = "synthetic zebrafish"
    11.times do |index|
      Oldreport.create!(legacy_id: "TEST-#{index}", title: "Example archive entry #{index}",
        description: query, date_of: Date.new(2024, 1, 1) + index.days)
    end

    post old_search_path, params: { query: query }

    assert_response :success
    assert_select "article.record-card", count: 10
    assert_select "nav[aria-label='Search result pages'] form[method='post'][action=?]", old_search_path do
      assert_select "input[type='hidden'][name='query'][value=?]", query
      assert_select "button[name='page'][value='2']", text: "Next"
    end

    post old_search_path, params: { query: query, page: 2 }

    assert_response :success
    assert_select "article.record-card", count: 1
  end

  test "call 911 filter highlights published active suspensions" do
    sign_in users(:one)
    active = suspensions(:one)
    draft = suspensions(:two)
    active.incident.update!(published: true, draft: false)
    draft.incident.update!(published: false, draft: true)
    [active, draft].each { |suspension| suspension.update!(until: Date.current + 2.days, call_police: true) }

    get patrons_list_path(suspended: true, call_911: true)

    assert_response :success
    assert_select "article.record-card", count: 1
    assert_select "article.record-card a[href=?]", patrons_view_path(id: active.patron_id)
    assert_select ".status-label-urgent", text: "Call 911 immediately if seen on property"
  end
end
