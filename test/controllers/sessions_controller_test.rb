require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "staff sign-in preserves a local deep link and signs out by POST" do
    incident = incidents(:one)
    incident.update!(published: true)

    get incidents_view_path(id: incident.id)
    assert_redirected_to sign_in_path
    follow_redirect!
    assert_select "form[action='/auth/google_oauth2'][method=post]"
    assert_includes response.headers["Cache-Control"], "no-store"

    sign_in users(:one)
    assert_redirected_to incidents_view_path(id: incident.id)

    get "/signout"
    assert_response :not_found

    post signout_path
    assert_redirected_to sign_in_path
    assert_response :see_other
    get incidents_view_path(id: incident.id)
    assert_redirected_to sign_in_path
  end

  test "only accepts a verified Google Workspace identity" do
    with_google_auth(users(:one), domain: "other.example") do
      get "/auth/google_oauth2/callback"
      assert_redirected_to sign_in_path
    end

    with_google_auth(users(:one), verified: false) do
      get "/auth/google_oauth2/callback"
      assert_redirected_to sign_in_path
    end

    with_google_auth(users(:one), uid: "") do
      get "/auth/google_oauth2/callback"
      assert_redirected_to sign_in_path
    end

    get root_path
    assert_redirected_to sign_in_path
  end

  test "uses Google subject as identity and stores no access token" do
    staff = User.new(uid: "new-synthetic-subject", email: "new@example.org", name: "New Synthetic Staff")
    assert_difference "User.count" do
      sign_in staff
    end
    user = User.find_by!(uid: staff.uid)
    assert_equal "new@example.org", user.email
    assert_nil user.oauth_token
    assert_nil user.avatar
    assert_no_difference "User.count" do
      sign_in staff
    end
  end

  test "ignores externally supplied OAuth return URLs" do
    with_google_auth(users(:one)) do
      post "/auth/google_oauth2", params: { origin: "https://outside.example" }
      assert_response :redirect
      follow_redirect!
      assert_redirected_to root_path
    end
  end

  test "expired or deleted staff sessions require sign-in again" do
    sign_in users(:one)
    travel 13.hours do
      get root_path
      assert_redirected_to sign_in_path
    end

    sign_in users(:two)
    users(:two).destroy!
    get root_path
    assert_redirected_to sign_in_path
  end

  test "write endpoints require a CSRF token" do
    sign_in users(:one)
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    assert_no_difference "Comment.count" do
      post comments_save_path, params: { comment_for: "patron", owner_id: patrons(:one).id, description: "Synthetic comment" }
      assert_response :unprocessable_content
    end
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end
end
