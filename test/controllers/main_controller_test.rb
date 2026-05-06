require "test_helper"

class MainControllerTest < ActionDispatch::IntegrationTest
  test "root shows login page for signed out staff" do
    get root_path

    assert_response :success
    assert_includes response.body, "Staff Login"
  end

  test "root redirects signed in staff to incidents" do
    user = create_user
    sign_in_as(user)

    get root_path

    assert_redirected_to incidents_path
  end
end
