require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "staff can post comments on published reports" do
    incident = incidents(:one)
    incident.update!(published: true)
    sign_in users(:two)

    assert_enqueued_with job: CommentAddedJob do
      assert_difference "incident.incident_comments.count" do
        post comments_save_path, params: { comment_for: "incident", owner_id: incident.id, description: "Synthetic follow-up" }
      end
    end
    assert_redirected_to incidents_view_path(id: incident.id)
    assert_equal users(:two), incident.incident_comments.order(:id).last.user
  end

  test "unrelated staff cannot amend another person's comment" do
    sign_in users(:two)
    comment = comments(:one)
    incidents(:one).update!(published: true)
    original_description = comment.description

    post comments_update_path, params: { comment_for: "incident", owner_id: comment.incident_id, id: comment.id, description: "Changed" }
    assert_response :forbidden
    assert_equal original_description, comment.reload.description

    post comments_delete_path, params: { comment_for: "incident", owner_id: comment.incident_id, id: comment.id }
    assert_response :forbidden
  end

  test "comments on another staff member's draft are hidden" do
    incident = incidents(:one)
    incident.update!(created_by: users(:one).id.to_s, published: false)
    sign_in users(:two)

    assert_no_difference "Comment.count" do
      post comments_save_path, params: { comment_for: "incident", owner_id: incident.id, description: "Synthetic follow-up" }
    end
    assert_response :not_found
  end

  test "draft comments stay in app and empty comments are rejected" do
    incident = incidents(:one)
    incident.update!(created_by: users(:one).id.to_s, published: false)
    sign_in users(:one)

    assert_no_enqueued_jobs only: CommentAddedJob do
      assert_difference "Comment.count" do
        post comments_save_path, params: { comment_for: "incident", owner_id: incident.id, description: "Draft follow-up" }
      end
    end
    assert_redirected_to incidents_view_path(id: incident.id)

    assert_no_difference "Comment.count" do
      post comments_save_path, params: { comment_for: "patron", owner_id: patrons(:two).id, description: " " }
    end
    assert_redirected_to patrons_view_path(id: patrons(:two).id)
  end

  test "the parent scope is verified and authors can update and delete" do
    sign_in users(:two)
    comment = comments(:two)
    post comments_update_path, params: { comment_for: "patron", owner_id: patrons(:one).id, id: comment.id, description: "Changed" }
    assert_response :not_found

    post comments_update_path, params: { comment_for: "patron", owner_id: comment.patron_id, id: comment.id, description: "Changed" }
    assert_redirected_to patrons_view_path(id: comment.patron_id)
    assert_equal "Changed", comment.reload.description

    assert_difference "Comment.count", -1 do
      post comments_delete_path, params: { comment_for: "patron", owner_id: comment.patron_id, id: comment.id }
    end
    assert_redirected_to patrons_view_path(id: comment.patron_id)
  end
end
