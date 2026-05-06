require "test_helper"

class PatronControllerTest < ActionDispatch::IntegrationTest
  test "signed in staff can list patrons" do
    user = create_user
    sign_in_as(user)

    get "/patrons/list"

    assert_response :success
  end

  test "incident owner can add existing patron to incident" do
    user = create_user
    incident = create_incident(created_by: user)
    patron = create_patron
    sign_in_as(user)

    assert_difference "Violation.count", 1 do
      post "/patrons/add_existing_to_incident.js", params: {
        incident_id: incident.id,
        patron_id: patron.id
      }
    end
  end

  test "non owner cannot add patron to incident without edit permission" do
    owner = create_user(email: "owner@tadl.org")
    other = create_user(email: "other@tadl.org")
    incident = create_incident(created_by: owner)
    patron = create_patron
    sign_in_as(other)

    assert_no_difference "Violation.count" do
      post "/patrons/add_existing_to_incident.js", params: {
        incident_id: incident.id,
        patron_id: patron.id
      }
    end
  end

  test "only configured suspenders can create suspensions" do
    owner = create_user(email: "owner@tadl.org")
    incident = create_incident(created_by: owner)
    patron = create_patron
    sign_in_as(owner)

    assert_no_difference "Suspension.count" do
      post "/patrons/save_suspension.js", params: {
        incident_id: incident.id,
        patron_id: patron.id,
        until: "2026-05-20"
      }
    end

    ENV["CAN_SUSPEND"] = owner.email
    assert_difference "Suspension.count", 1 do
      post "/patrons/save_suspension.js", params: {
        incident_id: incident.id,
        patron_id: patron.id,
        until: "2026-05-20"
      }
    end
  end
end
