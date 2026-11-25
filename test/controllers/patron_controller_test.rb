require "test_helper"

class PatronControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    @incident = incidents(:one)
    @incident.update_columns(created_by: @user.id, published: true)
    @patron = patrons(:two)
    sign_in(@user)
  end

  test "patron actions are in the detail heading and excluded from browse and search" do
    detail_path = patrons_view_path(id: @patron.id)
    edit_path = patrons_edit_path(patron_id: @patron.id)
    delete_button = "button[data-patron-action='delete']"

    with_env("SUPER_ADMIN" => @user.email) do
      get patrons_list_path
      assert_response :success
      assert_select "main a[href=?]", detail_path
      assert_select "main a[href=?]", edit_path, count: 0
      assert_select delete_button, count: 0

      post patrons_search_path, params: { query: @patron.first_name }
      assert_response :success
      assert_select "main a[href=?]", detail_path
      assert_select "main a[href=?]", edit_path, count: 0
      assert_select delete_button, count: 0

      get detail_path
      assert_response :success
      assert_select "main header" do
        assert_select "h1", text: "Patron record"
        assert_select "a[href=?]", edit_path, text: "Edit patron record"
        assert_select delete_button, text: "Delete patron"
      end
    end

    with_env("SUPER_ADMIN" => nil) do
      get detail_path
      assert_response :success
      assert_select "main header a[href=?]", edit_path
      assert_select delete_button, count: 0
    end
  end

  test "creates and links a patron without inserting a legacy violation" do
    assert_difference "Patron.count", 1 do
      assert_difference "IncidentPatron.count", 1 do
        assert_no_difference "Violation.count" do
          post patrons_save_path(format: :js), params: { incident_id: @incident.id, known_as: "Synthetic alias" }, xhr: true
        end
      end
    end

    assert_response :success
    assert @incident.patrons.exists?(known_as: "Synthetic alias")
  end

  test "attaches an existing patron idempotently and displays their published history" do
    assert_difference "IncidentPatron.count", 1 do
      assert_no_difference "Violation.count" do
        2.times do
          post patrons_add_existing_to_incident_path(format: :js), params: ids, xhr: true
          assert_response :success
        end
      end
    end

    get patrons_view_path(id: @patron.id)
    assert_response :success
    assert_includes response.body, @incident.title
  end

  test "does not create an orphan patron when staff cannot edit the incident" do
    sign_in(users(:two))

    assert_no_difference "Patron.count" do
      post patrons_save_path(format: :js), params: { incident_id: @incident.id, known_as: "Synthetic alias" }, xhr: true
    end
    assert_response :forbidden
  end

  test "cannot suspend a patron unless they are linked to the incident" do
    with_env("CAN_SUSPEND" => @user.email) do
      assert_no_difference "Suspension.count" do
        post patrons_save_suspension_path(format: :js), params: ids.merge(until: Date.current + 2), xhr: true
      end
    end
    assert_response :not_found
  end

  test "suspension permission and incident/patron scope precede every write" do
    @incident.patrons << @patron
    other_suspension = suspensions(:two)
    requested = ids.merge(suspension_id: other_suspension.id, until: Date.current + 2)

    assert_no_changes -> { other_suspension.reload.attributes } do
      post patrons_save_suspension_path(format: :js), params: requested, xhr: true
      assert_response :forbidden

      with_env("CAN_SUSPEND" => @user.email) do
        post patrons_save_suspension_path(format: :js), params: requested, xhr: true
        assert_response :not_found
      end
    end
  end

  test "staff allowed to suspend can issue a suspension for a linked published incident" do
    @incident.patrons << @patron

    with_env("CAN_SUSPEND" => @user.email) do
      assert_difference "Suspension.count", 1 do
        assert_enqueued_jobs 1, only: SuspensionPublishedJob do
          post patrons_save_suspension_path(format: :js), params: ids.merge(until: Date.current + 2, call_police: "true"), xhr: true
        end
      end
    end

    assert_response :success
    suspension = @incident.suspensions.find_by!(patron: @patron)
    assert suspension.call_police?
    assert_not suspension.issued_email_sent?
  end

  test "staff can add a letter later, download it from both records, and remove the attachment" do
    suspension = suspensions(:one)
    patron = suspension.patron
    @incident.patrons << patron
    pdf = "%PDF-1.4\n%%EOF\n"
    letter = Rack::Test::UploadedFile.new(StringIO.new(pdf), "application/pdf",
      original_filename: "example-letter.pdf")
    params = { incident_id: @incident.id, patron_id: patron.id, suspension_id: suspension.id }

    with_env("CAN_SUSPEND" => @user.email) do
      assert_no_enqueued_jobs(only: SuspensionPublishedJob) do
        post patrons_save_suspension_path(format: :js),
          params: params.merge(until: Date.current + 2, letter_sent: "true", letter: letter), xhr: true
      end
      assert_response :success
      assert suspension.reload.letter_sent?

      download_path = private_attachment_path(suspension.letter.attachment)
      [incidents_view_path(id: @incident.id), patrons_view_path(id: patron.id)].each do |path|
        get path
        assert_response :success
        assert_select "a[href=?]", download_path, text: "Download suspension letter"
      end

      get download_path
      assert_response :success
      assert_equal pdf, response.body

      post patrons_delete_letter_path(format: :js), params: params, xhr: true
      assert_response :success
      assert_not suspension.reload.letter.attached?
      assert suspension.letter_sent?
      get download_path
      assert_response :not_found
    end
  end

  test "incident and patron records label the suspension end date" do
    suspension = suspensions(:one)
    patron = suspension.patron
    @incident.patrons << patron

    [incidents_view_path(id: @incident.id), patrons_view_path(id: patron.id)].each do |path|
      get path
      assert_response :success
      assert_select "p.record-related", text: /Suspended until\s+08\/16\/2022\./
    end

    suspension.update_column(:until, nil)
    get incidents_view_path(id: @incident.id)
    assert_response :success
    assert_select "p.record-related", text: /Suspension\s+End date unavailable\./
  end

  test "plain incident link removal preserves a suspension unless authorized to revoke it" do
    @incident.patrons << @patron
    @incident.suspensions.create!(patron: @patron, until: Date.current + 2)

    assert_no_difference ["Suspension.count", "IncidentPatron.count"] do
      post patrons_remove_patron_from_incident_path(format: :js), params: ids, xhr: true
    end
    assert_response :forbidden

    with_env("CAN_SUSPEND" => @user.email) do
      assert_difference ["Suspension.count", "IncidentPatron.count"], -1 do
        post patrons_remove_patron_from_incident_path(format: :js), params: ids, xhr: true
      end
      assert_response :success
    end
  end

  test "call 911 list includes only active published emergency suspensions" do
    patron = patrons(:one)
    patron.update!(first_name: "Emergency")
    @patron.update!(first_name: "Limited")
    suspensions(:one).update!(call_police: true, until: Date.current + 10)
    suspensions(:two).update!(call_police: true, until: Date.current + 10)

    get patrons_list_path(suspended: true, call_911: true)
    assert_response :success
    assert_includes response.body, "Emergency"
    assert_not_includes response.body, "Limited"
  end

  test "the suspension calendar requires a staff session" do
    open_session do |signed_out|
      signed_out.get patrons_suspension_calendar_path(month: "2026-11")
      signed_out.assert_redirected_to sign_in_path
    end
  end

  test "the suspension calendar defaults to this month and accepts future months" do
    travel_to Time.zone.local(2026, 11, 25, 12) do
      [nil, "2026-10", "2026-13", "2026-2", { year: "2026" }].each do |month|
        get patrons_suspension_calendar_path, params: { month: month }
        assert_response :success
        assert_select "#suspension-month", text: "November 2026"
      end

      get patrons_suspension_calendar_path(month: "2027-01")
      assert_response :success
      assert_select "#suspension-month", text: "January 2027"
      assert_select ".empty-results", text: "No upcoming suspension end dates this month."
    end
  end

  test "the calendar lists each patron once on their latest published suspension end date" do
    travel_to Time.zone.local(2026, 11, 25, 12) do
      today = Date.current
      last_day = today.end_of_month
      next_month = today.next_month.beginning_of_month
      ending_today = calendar_patron("Ends today", today)
      ending_last_day = calendar_patron("Ends on final day", last_day)
      overlapping = calendar_patron("Overlapping dates", today + 1)
      expired = calendar_patron("Already expired", today - 1)
      undated = calendar_patron("End date unavailable", nil)
      draft_only = calendar_patron("Only a draft", today + 1, incident: incidents(:two))

      incidents(:two).update!(published: false, draft: true)
      add_calendar_suspension(overlapping, next_month.next_month, incidents(:two))
      ["Synthetic calendar incident A", "Synthetic calendar incident B"].each do |title|
        published = Incident.create!(title: title, description: "Synthetic test report", location: "Woodmere",
          date_of: Time.current, published: true)
        add_calendar_suspension(overlapping, next_month, published)
      end

      get patrons_suspension_calendar_path
      assert_response :success
      assert_calendar_patron(ending_today, today)
      assert_calendar_patron(ending_last_day, last_day)
      assert_select ".suspension-month-grid" do
        [overlapping, expired, undated, draft_only].each do |patron|
          assert_select "a[href=?]", patrons_view_path(id: patron.id), count: 0
        end
      end

      get patrons_suspension_calendar_path(month: next_month.strftime("%Y-%m"))
      assert_response :success
      assert_calendar_patron(overlapping, next_month)
      assert_select ".suspension-month-grid" do
        [ending_today, ending_last_day, expired, undated, draft_only].each do |patron|
          assert_select "a[href=?]", patrons_view_path(id: patron.id), count: 0
        end
      end
    end
  end

  test "incident and patron details keep historical emergency flags without active instructions" do
    suspension = suspensions(:one)
    patron = suspension.patron
    @incident.patrons << patron
    suspension.update!(call_police: true, until: Date.current + 2)

    [incidents_view_path(id: @incident.id), patrons_view_path(id: patron.id)].each do |path|
      get path
      assert_response :success
      assert_select ".status-label-urgent", count: 1
      assert_select "p.record-related", /Please call 911 immediately/
    end

    suspension.update!(until: Date.current)

    [incidents_view_path(id: @incident.id), patrons_view_path(id: patron.id)].each do |path|
      get path
      assert_response :success
      assert_select ".status-label-urgent", count: 0
      assert_select "p.record-related", /Call 911 flag recorded/
      assert_select "p.record-related", { text: /Please call 911 immediately/, count: 0 }
    end

    suspension.update!(until: Date.current + 2)
    @incident.update!(published: false, draft: true)

    get incidents_view_path(id: @incident.id)
    assert_response :success
    assert_select ".status-label-urgent", count: 0
    assert_select "p.record-related", /Call 911 flag recorded/
    assert_select "p.record-related", { text: /Please call 911 immediately/, count: 0 }
  end

  test "invalid expiration cannot create a partial suspension" do
    @incident.patrons << @patron

    with_env("CAN_SUSPEND" => @user.email) do
      assert_no_difference "Suspension.count" do
        post patrons_save_suspension_path(format: :js), params: ids.merge(until: "invalid"), xhr: true
      end
    end
    assert_response :success
    assert_includes response.body, "Until"
  end

  private

  def calendar_patron(name, end_date, incident: @incident)
    Patron.create!(known_as: name).tap do |patron|
      add_calendar_suspension(patron, end_date, incident)
    end
  end

  def add_calendar_suspension(patron, end_date, incident)
    incident.patrons << patron
    suspension = incident.suspensions.create!(patron:, until: end_date || Date.current)
    suspension.update_column(:until, nil) unless end_date
  end

  def assert_calendar_patron(patron, date)
    patron_path = patrons_view_path(id: patron.id)
    assert_select ".suspension-month-grid" do
      assert_select "a[href=?]", patron_path, count: 1
      assert_select "td[data-date=?] a[href=?]", date.iso8601, patron_path
    end
    assert_select ".suspension-agenda li[data-date=?] a[href=?]", date.iso8601, patron_path
  end

  def ids
    { incident_id: @incident.id, patron_id: @patron.id }
  end
end
