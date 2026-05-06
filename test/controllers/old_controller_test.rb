require "test_helper"

class OldControllerTest < ActionDispatch::IntegrationTest
  test "signed in staff can browse legacy reports" do
    user = create_user
    sign_in_as(user)

    get "/old/list"
    assert_response :success

    get "/old/view", params: { id: oldreports(:one).id }
    assert_response :success
  end
end
