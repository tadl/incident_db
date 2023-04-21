require "test_helper"

class OldControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get old_list_url
    assert_response :success
  end

  test "should get show" do
    get old_show_url
    assert_response :success
  end
end
