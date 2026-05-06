require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "login returns to stored local path" do
    get "/incidents/search"
    assert_redirected_to root_path

    user = create_user
    sign_in_as(user)

    assert_redirected_to "/incidents/search"
  end

  test "external return paths are rejected" do
    controller = ApplicationController.new

    assert_nil controller.send(:safe_return_path, "https://evil.example/path")
    assert_nil controller.send(:safe_return_path, "//evil.example/path")
    assert_equal "/incidents", controller.send(:safe_return_path, "/incidents")
  end
end
