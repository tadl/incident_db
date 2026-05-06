require "test_helper"

class IncidentsControllerTest < ActionDispatch::IntegrationTest
  test "signed out staff are sent to login page" do
    get incidents_path

    assert_redirected_to root_path
  end

  test "signed in staff can list and create incident reports" do
    user = create_user
    sign_in_as(user)

    get incidents_path
    assert_response :success

    get "/incidents/new"
    assert_response :success
  end

  test "incident owner can update a draft" do
    user = create_user
    incident = create_incident(created_by: user, published: false, draft: true)
    sign_in_as(user)

    post "/incidents/save.js", params: {
      incident_id: incident.id,
      title: "Updated title",
      description: "Updated description",
      location: "Updated location",
      date_of: "05/01/2026, 12:00"
    }

    assert_response :success
    assert_equal "Updated title", incident.reload.title
  end

  test "non owner cannot update an incident without edit permission" do
    owner = create_user(email: "owner@tadl.org")
    other = create_user(email: "other@tadl.org")
    incident = create_incident(created_by: owner)
    sign_in_as(other)

    post "/incidents/save.js", params: {
      incident_id: incident.id,
      title: "Unauthorized title",
      description: "Updated description",
      location: "Updated location",
      date_of: "05/01/2026, 12:00"
    }

    assert_response :success
    assert_not_equal "Unauthorized title", incident.reload.title
  end

  test "configured editors can update incidents they did not create" do
    owner = create_user(email: "owner@tadl.org")
    editor = create_user(email: "editor@tadl.org")
    ENV["CAN_EDIT"] = editor.email
    incident = create_incident(created_by: owner)
    sign_in_as(editor)

    post "/incidents/save.js", params: {
      incident_id: incident.id,
      title: "Editor title",
      description: "Editor description",
      location: "Updated location",
      date_of: "05/01/2026, 12:00"
    }

    assert_response :success
    assert_equal "Editor title", incident.reload.title
  end
end
