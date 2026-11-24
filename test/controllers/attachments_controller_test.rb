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
    get private_attachment_path(@attachment), headers: { "Accept" => "image/png" }
    assert_response :unauthorized
    get private_thumbnail_path(@attachment), headers: { "Accept" => "text/html" }
    assert_response :unauthorized
  end

  test "a suspension letter link from a staff notice resumes after sign-in" do
    suspension = suspensions(:one)
    suspension.incident.update!(published: true, draft: false)
    pdf = "%PDF-1.4\n%%EOF\n"
    suspension.letter.attach(io: StringIO.new(pdf), filename: "synthetic-letter.pdf", content_type: "application/pdf")
    letter_path = private_attachment_path(suspension.letter.attachment)

    get letter_path, headers: { "Accept" => "text/html" }
    assert_redirected_to sign_in_path
    assert_includes response.headers["Cache-Control"], "no-store"

    sign_in users(:two)
    assert_redirected_to letter_path
    follow_redirect!
    assert_response :success
    assert_match(/\Aattachment;/, response.headers["Content-Disposition"])
    assert_equal pdf, response.body
  end

  test "a staff member signing in through a draft photo link still needs permission to view it" do
    photo_path = private_attachment_path(@attachment)
    get photo_path, headers: { "Accept" => "text/html" }
    assert_redirected_to sign_in_path

    sign_in users(:two)
    assert_redirected_to photo_path
    follow_redirect!
    assert_response :not_found
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
