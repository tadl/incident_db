require "test_helper"
require "base64"

class IncidentsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    @incident = incidents(:one)
    @incident.update_columns(created_by: @user.id, draft: true)
    sign_in(@user)
  end

  test "opens the new editor" do
    get incidents_new_path

    assert_response :success
    assert_select 'input#date_of[type="datetime-local"]'
  end

  test "the published list shows delete only to configured admins" do
    @incident.update_columns(published: true, draft: false)
    selector = 'button[data-incident-action="delete"][data-incident-id=?]'

    with_env("SUPER_ADMIN" => nil) do
      get incidents_path
      assert_response :success
      assert_select selector, @incident.id.to_s, count: 0
    end

    with_env("SUPER_ADMIN" => @user.email) do
      get incidents_path
      assert_response :success
      assert_select selector, @incident.id.to_s, text: "Delete"
    end
  end

  test "saves an Eastern timestamp and transitions a draft to published exactly once" do
    assert_enqueued_jobs 0, only: IncidentMailerJob do
      submit_incident(draft: "true")
    end
    assert_response :success
    assert @incident.reload.draft?
    assert_equal Time.zone.local(2026, 11, 24, 13, 15), @incident.date_of

    assert_enqueued_jobs 1, only: IncidentMailerJob do
      submit_incident
      assert_response :success
      submit_incident(draft: "true")
      assert_response :success
    end
    assert @incident.reload.published?
    assert_not @incident.draft?
  end

  test "persists and clears a freeform summary while retaining linked patron and historical codes" do
    patron = patrons(:one)
    @incident.patrons << patron
    entry = violations(:one)
    text = "A synthetic policy narrative"

    submit_incident(violation_summaries: { patron.id.to_s => { description: "  #{text}  " } })

    assert_response :success
    summary = @incident.violation_summaries.find_by!(patron:)
    assert_equal text, summary.description

    get incidents_view_path(id: @incident.id)
    assert_response :success
    assert_includes response.body, text
    assert_includes response.body, entry.description

    submit_incident(violation_summaries: { patron.id.to_s => { description: "" } })
    assert_response :success
    assert_not ViolationSummary.exists?(summary.id)
    assert @incident.patrons.exists?(patron.id)
    assert Violation.exists?(entry.id)
  end

  test "unlinked violation summary rolls back publishing and other changes" do
    assert_no_changes -> { @incident.reload.attributes } do
      assert_no_difference "ViolationSummary.count" do
        assert_enqueued_jobs 0 do
          submit_incident(violation_summaries: { patrons(:two).id.to_s => { description: "Unlinked synthetic patron" } })
        end
      end
    end
    assert_response :success
    assert_includes response.body, "no longer linked"
  end

  test "invalid date returns an editor error and preserves the draft" do
    assert_no_changes -> { @incident.reload.attributes } do
      submit_incident(date_of: "2026-02-30T13:15")
    end
    assert_response :success
    assert_includes response.body, "Date of"
  end

  test "other staff cannot read or edit another staff member's draft" do
    sign_in(users(:two))

    get incidents_view_path(id: @incident.id)
    assert_response :not_found
    get incidents_edit_path(id: @incident.id)
    assert_response :forbidden
    submit_incident
    assert_response :forbidden
    assert @incident.reload.draft?
  end

  test "incident search includes freeform violations and excludes drafts" do
    @incident.patrons << patrons(:one)
    submit_incident(violation_summaries: { patrons(:one).id.to_s => { description: "Moonstone drill" } })

    other = incidents(:two)
    other.update_columns(title: "Moonstone draft", draft: true, published: false)
    post incidents_search_path, params: { query: "Moonstone" }

    assert_response :success
    assert_includes response.body, @incident.reload.title
    assert_not_includes response.body, other.title
  end

  test "removing an image requires the attachment to belong to the edited incident" do
    image = Base64.strict_decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aKbkAAAAASUVORK5CYII=")
    other = incidents(:two)
    other.images.attach(io: StringIO.new(image), filename: "synthetic.png", content_type: "image/png")
    attachment = other.images.first

    assert_no_difference "ActiveStorage::Attachment.count" do
      post incidents_delete_image_path(format: :js), params: { incident_id: @incident.id, image_id: attachment.id }, xhr: true
    end
    assert_response :not_found
    assert other.images.attached?
  end

  test "rejects non-AJAX writes without publishing the draft" do
    post incidents_save_path(format: :js), params: { incident_id: @incident.id }

    assert_response :not_acceptable
    assert @incident.reload.draft?
  end

  private

  def submit_incident(**attributes)
    params = {
      incident_id: @incident.id,
      title: "Synthetic incident",
      description: "Test narrative",
      location: "Test location",
      date_of: "2026-11-24T13:15",
      draft: "false"
    }.merge(attributes)
    post incidents_save_path(format: :js), params: params, xhr: true
  end
end
