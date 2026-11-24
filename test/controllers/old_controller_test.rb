require "test_helper"

class OldControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in(users(:one)) }

  test "lists and opens historical incidents" do
    get old_list_path
    assert_response :success

    report = oldreports(:one)
    report.update_columns(a_violations: "A1A2", b_violations: "B2")
    get old_view_path(id: report.id)
    assert_response :success
    assert_includes response.body, "A1, A2, B2"
  end

  test "searches historical reports without an external index" do
    oldreports(:one).update_columns(narrative: "Synthetic historical narrative")
    post old_search_path, params: { query: "historical" }
    assert_response :success
    assert_select "a[href=?]", old_view_path(id: oldreports(:one).id)
  end
end
