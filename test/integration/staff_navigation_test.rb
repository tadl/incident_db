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
    assert_select "h1 i.fa-person-falling-burst[aria-hidden='true']"
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
    %w[top bottom].each do |position|
      assert_select "nav[aria-label='Search result pages at #{position}'] form[method='post'][action=?]", old_search_path do
        assert_select "input[type='hidden'][name='query'][value=?]", query
        assert_select "input[name='query'][id]", count: 0
        assert_select "button[name='page'][value='2']", text: "Next"
      end
    end

    post old_search_path, params: { query: query, page: 2 }

    assert_response :success
    assert_select "article.record-card", count: 1
  end

  test "both draft pagination controls keep the draft filter" do
    user = users(:one)
    sign_in user
    11.times do |index|
      Incident.create!(created_by: user.id, draft: true, title: "Example report #{index}",
        date_of: Time.zone.local(2025, 1, 1) + index.days, location: "Woodmere", description: "Synthetic report")
    end

    get incidents_path(just_drafts: true)

    assert_response :success
    %w[top bottom].each do |position|
      assert_select "nav[aria-label='Result pages at #{position}']" do
        assert_select "[aria-current='page']", text: "1"
        assert_select "a[href*='just_drafts=true'][href*='page=2']", text: "Next"
      end
    end
    assert_select "nav.list-pagination nav", count: 0
  end

  test "both patron search controls retain the unknown-name filter" do
    sign_in users(:one)
    6.times { |index| Patron.create!(known_as: "Fictional zebrafish alias #{index}") }

    post patrons_search_path, params: { query: "zebrafish", unknown_only: "true" }

    assert_response :success
    %w[top bottom].each do |position|
      assert_select "nav[aria-label='Search result pages at #{position}'] form[method='post'][action=?]", patrons_search_path do
        assert_select "input[type='hidden'][name='query'][value='zebrafish']"
        assert_select "input[type='hidden'][name='unknown_only'][value='true']"
        assert_select "button[name='page'][value='2']", text: "Next"
      end
    end
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
