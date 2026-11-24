require "test_helper"

class DestructiveActionsTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  CONFIRMATION = "dialog[data-destructive-confirmation][open]"

  def after_teardown
    Capybara.current_session.driver.quit
    super
  end

  test "an administrator deletes a published incident from its detail page" do
    user = users(:one)
    incident = incidents(:one)
    incident.update!(created_by: users(:two).id, published: true)

    with_env("SUPER_ADMIN" => user.email, "CAN_EDIT" => "") do
      with_google_auth(user) do
        visit incidents_path
        click_button "Sign in with Google"
        assert_link incident.title
        assert_no_selector "[data-incident-action='delete']"
        click_link incident.title
        assert_no_link "Edit incident"

        click_button "Delete incident"
        within CONFIRMATION do
          assert_selector "h2", text: "Delete incident?"
          assert_selector "button:focus", text: "Cancel"
          click_button "Cancel"
        end
        assert_no_selector CONFIRMATION
        assert Incident.exists?(incident.id)

        click_button "Delete incident"
        within(CONFIRMATION) { click_button "Delete incident" }
        assert_current_path incidents_path
        assert_not Incident.exists?(incident.id)
      end
    end
  end

  test "comment deletion opens the shared dialog and submits the original form only on confirmation" do
    incident = incidents(:one)
    incident.update!(published: true)
    user = users(:one)
    comment = incident.incident_comments.create!(user: user, description: "Synthetic comment to remove")
    card = "##{ActionView::RecordIdentifier.dom_id(comment, :entry)}"
    previous_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    with_google_auth(user) do
      report_path = incidents_view_path(id: incident.id)
      visit report_path
      click_button "Sign in with Google"
      assert_current_path report_path
      within(card) { find("summary", text: "Edit comment").click }

      within(card) { click_button "Delete comment" }
      within(CONFIRMATION) { click_button "Cancel" }
      assert_no_selector CONFIRMATION
      assert Comment.exists?(comment.id)

      within(card) { click_button "Delete comment" }
      within(CONFIRMATION) { click_button "Delete comment" }
      # The form redirects back to the same URL. Wait for the card to leave the DOM
      # without asking Chrome to inspect visibility in the document being replaced.
      assert_no_selector card, visible: :all
      assert_current_path report_path
      assert_selector "#comments-heading", visible: :all
      assert_not Comment.exists?(comment.id)
    end
  ensure
    ActionController::Base.allow_forgery_protection = previous_forgery_protection
  end

  test "suspension confirmations preserve focus and cancel inside the edit modal" do
    user = users(:one)
    incident = incidents(:one)
    incident.update!(created_by: user.id, published: true)
    suspension = suspensions(:one)
    incident.patrons << suspension.patron
    suspension.letter.attach(io: StringIO.new("%PDF-1.4\n%%EOF\n"),
      filename: "synthetic-letter.pdf", content_type: "application/pdf")

    with_env("CAN_SUSPEND" => user.email) do
      with_google_auth(user) do
        visit incidents_edit_path(id: incident.id)
        click_button "Sign in with Google"
        click_button "Edit suspension"

        within ".modal.show" do
          find("button[aria-label='Remove suspension letter']").click
          within CONFIRMATION do
            assert_selector "button:focus", text: "Cancel"
            find("button", text: "Cancel").send_keys(:escape)
          end
          assert_no_selector CONFIRMATION
          assert_selector "button:focus[aria-label='Remove suspension letter']"
          assert suspension.reload.letter.attached?

          find("button[aria-label='Remove suspension letter']").click
          within(CONFIRMATION) { click_button "Remove letter" }
          assert_text "Add Suspension Letter"
          assert_not suspension.reload.letter.attached?

          click_button "Revoke Suspension"
          within(CONFIRMATION) { click_button "Revoke suspension" }
        end

        assert_no_selector ".modal.show"
        assert_button "Suspend patron"
        assert_not Suspension.exists?(suspension.id)
      end
    end
  end
end
