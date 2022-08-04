require "test_helper"

class PatronControllerTest < ActionDispatch::IntegrationTest
  test "should get save" do
    get patron_save_url
    assert_response :success
  end

  test "should get edit" do
    get patron_edit_url
    assert_response :success
  end

  test "should get list" do
    get patron_list_url
    assert_response :success
  end

  test "should get show" do
    get patron_show_url
    assert_response :success
  end
end
