require "test_helper"

class IncidentsControllerTest < ActionDispatch::IntegrationTest
  test "should get all" do
    get incidents_all_url
    assert_response :success
  end

  test "should get new" do
    get incidents_new_url
    assert_response :success
  end

  test "should get edit" do
    get incidents_edit_url
    assert_response :success
  end

  test "should get save" do
    get incidents_save_url
    assert_response :success
  end
end
