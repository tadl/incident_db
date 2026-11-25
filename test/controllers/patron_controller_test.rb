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

  def ids
    { incident_id: @incident.id, patron_id: @patron.id }
  end
end
