require "test_helper"
require "base64"
require "tempfile"

class StaffWorkflowTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  # Restart the clean browser session between tests. Chrome rejects the
  # wildcard storage origin used by Capybara's automatic reset.
  def after_teardown
    Capybara.current_session.driver.quit
    super
  end

  test "staff can sign in, publish a draft and post extra information" do
    previous_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    with_google_auth(users(:one)) do
      visit incidents_new_path
      click_button "Sign in with Google"
      assert_current_path incidents_new_path

      click_button "Publish incident"
      assert_selector "#messages", text: "Title can't be blank, Location can't be blank, and Description can't be blank"

      fill_in "Title", with: "Synthetic browser workflow"
      select "Woodmere", from: "Location"
      fill_in "Description", with: "A synthetic browser test report."
      click_button "Save as draft"

      assert_text "Draft"
      assert_text "Synthetic browser workflow"
      click_link "Edit incident"
      click_button "Publish incident"
      assert_current_path %r{\A/incidents/view\?id=\d+\z}

      fill_in "Add extra information", with: "Synthetic follow-up"
      click_button "Save extra information"
      assert_text "Synthetic follow-up"

      click_button "Sign out"
      assert_current_path sign_in_path
    end
  ensure
    ActionController::Base.allow_forgery_protection = previous_forgery_protection
  end

  test "cancel leaves patron edits and unsaved report edits unapplied" do
    patron = patrons(:one)
    with_google_auth(users(:one)) do
      visit patrons_edit_path(patron_id: patron.id)
      click_button "Sign in with Google"
      assert_current_path patrons_edit_path(patron_id: patron.id)

      assert_no_changes -> { patron.reload.first_name } do
        fill_in "First Name", with: "Unsaved synthetic name"
        click_link "Cancel"
        assert_current_path patrons_view_path(id: patron.id)
      end

      assert_no_difference ["Incident.count", "Patron.count", "IncidentPatron.count"] do
        visit incidents_new_path
        fill_in "Title", with: "Abandoned synthetic report"
        click_button "Add patron"
        within "#add_patron" do
          fill_in "First Name", with: "Abandoned synthetic patron"
          click_button "Add patron to incident"
        end
        assert_text "Abandoned synthetic patron"
        assert_current_path incidents_new_path
        click_link "Cancel"
        assert_current_path incidents_path
      end

      visit incidents_new_path
      fill_in "Title", with: "Saved synthetic draft"
      select "Woodmere", from: "Location"
      fill_in "Description", with: "Synthetic report description."
      click_button "Save as draft"
      assert_current_path %r{\A/incidents/view\?id=\d+\z}
      draft = Incident.find_by!(title: "Saved synthetic draft")

      click_link "Edit incident"
      fill_in "Title", with: "Unsaved synthetic draft changes"
      click_link "Cancel"
      assert_current_path incidents_view_path(id: draft.id)
      assert_text "Saved synthetic draft"
      assert_equal "Saved synthetic draft", draft.reload.title
    end
  end

  test "staff can choose existing and new patrons before entering required incident details" do
    existing = patrons(:one)
    existing.update!(first_name: "Synthetic Existing", middle_name: nil, last_name: nil, known_as: nil)
    png = Base64.strict_decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aKbkAAAAASUVORK5CYII=")

    Tempfile.create(["pending-patron", ".png"]) do |photo|
      photo.binmode
      photo.write(png)
      photo.flush

      with_google_auth(users(:one)) do
        visit incidents_new_path
        click_button "Sign in with Google"
        assert_current_path incidents_new_path

        assert_no_difference ["Incident.count", "Patron.count", "IncidentPatron.count", "ActiveStorage::Attachment.count"] do
          click_button "Add patron"
          within "#add_patron" do
            fill_in "First Name", with: "Synthetic Pending"
            attach_file "Add images to patron record", photo.path
            click_button "Add patron to incident"
          end
          assert_text "Synthetic Pending"
          fill_in "Violation summary", with: "Synthetic policy note"

          click_button "Add patron"
          click_button "Find an existing patron"
          within "#add_patron" do
            fill_in "Search patrons", with: "Synthetic Existing"
            click_button "Search"
            assert_text "Synthetic Existing"
            click_button "Add patron to incident"
          end

          click_button "Publish incident"
          assert_selector "#messages", text: "Title can't be blank"
          assert_text "Synthetic Pending"
          assert_text "Synthetic Existing"
          assert_field "Violation summary", with: "Synthetic policy note", count: 1
        end

        fill_in "Title", with: "Synthetic incident with pending patrons"
        select "Woodmere", from: "Location"
        fill_in "Description", with: "Synthetic incident narrative"
        click_button "Publish incident"
        assert_current_path %r{\A/incidents/view\?id=\d+\z}

        incident = Incident.find_by!(title: "Synthetic incident with pending patrons")
        created = incident.patrons.find_by!(first_name: "Synthetic Pending")
        assert incident.patrons.exists?(existing.id)
        assert_equal png, created.images.first.blob.download
        assert_equal "Synthetic policy note", incident.violation_summaries.find_by!(patron: created).description
      end
    end
  end

  test "cancel resets only the matching comment form" do
    incident = incidents(:one)
    incident.update!(published: true)
    comment = incident.incident_comments.create!(user: users(:one), description: "Synthetic original comment")
    card = "##{ActionView::RecordIdentifier.dom_id(comment, :entry)}"
    composer = "form[action='#{comments_save_path}']"

    with_google_auth(users(:one)) do
      visit incidents_view_path(id: incident.id)
      click_button "Sign in with Google"
      assert_current_path incidents_view_path(id: incident.id)
      fill_in "Add extra information", with: "Synthetic unsaved comment"

      within card do
        find("summary", text: "Edit comment").click
        fill_in "Comment", with: "Synthetic unsaved edit"
        click_button "Cancel"
        assert_selector "details:not([open])"
        find("summary", text: "Edit comment").click
        assert_field "Comment", with: comment.description
      end

      within composer do
        assert_field "Add extra information", with: "Synthetic unsaved comment"
        click_button "Cancel"
        assert_field "Add extra information", with: ""
      end
      assert_current_path incidents_view_path(id: incident.id)
    end
  end
end
