require "test_helper"
require "base64"

class AttachmentsControllerTest < ActionDispatch::IntegrationTest
  PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aKbkAAAAASUVORK5CYII=")

  setup do
    @incident = incidents(:one)
    @incident.update!(created_by: users(:one).id.to_s, published: false)
    @incident.images.attach(io: StringIO.new(PNG), filename: "synthetic.png", content_type: "image/png")
    @attachment = @incident.images.last
  end

  test "originals and thumbnails require a signed-in staff session" do
    get private_attachment_path(@attachment)
    assert_response :unauthorized
    get private_thumbnail_path(@attachment)
    assert_response :unauthorized
  end

  test "formerly public Active Storage endpoints are disabled" do
    get "/rails/active_storage/blobs/redirect/#{@attachment.blob.signed_id}/synthetic.png"
    assert_response :not_found
  end

  test "another staff member cannot fetch a draft attachment" do
    sign_in users(:two)
    get private_attachment_path(@attachment)
    assert_response :not_found
    get private_thumbnail_path(@attachment)
    assert_response :not_found
  end

  test "staff can fetch published media with private cache rules" do
    @incident.update!(published: true)
    sign_in users(:two)
    get private_attachment_path(@attachment)
    assert_response :success
    assert_equal PNG, response.body.b
    assert_includes response.headers["Cache-Control"], "no-store"

    get private_thumbnail_path(@attachment)
    assert_response :success
    assert_equal "image/png", response.media_type
    assert_includes response.headers["Cache-Control"], "no-store"
  end

  test "the owner can fetch a draft attachment" do
    sign_in users(:one)
    get private_attachment_path(@attachment)
    assert_response :success
  end
end
