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
