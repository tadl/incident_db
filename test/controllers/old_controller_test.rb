require "test_helper"
require "base64"

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

  test "finds an imported report by its original ID and displays its details and photo" do
    report = oldreports(:one)
    report.update!(legacy_id: "ARCHIVE-042", narrative: "Synthetic archived narrative",
      a_violations: "A1A2", b_violations: "B2", suspension: "Yes", suspension_duration: "30 days")
    png = Base64.strict_decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aKbkAAAAASUVORK5CYII=")
    report.images.attach(io: StringIO.new(png), filename: "synthetic-archive.png", content_type: "image/png")
    image = report.images.first
    detail_path = old_view_path(id: report.id)

    post old_search_path, params: { query: report.legacy_id }
    assert_response :success
    assert_select "a[href=?] img[src=?]", detail_path, private_thumbnail_path(image)

    get detail_path
    assert_response :success
    assert_select ".record-description", text: "Synthetic archived narrative"
    assert_select ".record-related", text: /Violations\s+A1, A2, B2/
    assert_select ".record-related", text: /Suspension\s+30 days/
    assert_select "a[href=?][data-image-preview]", private_attachment_path(image)

    get private_thumbnail_path(image)
    assert_response :success
    assert_equal "image/png", response.media_type
    get private_attachment_path(image)
    assert_response :success
    assert_equal png, response.body.b
  end
end
