require "test_helper"

class PendingPatronsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @incident = {
      title: "Synthetic report with provisional patrons",
      description: "Synthetic report details",
      location: "Woodmere",
      date_of: "2026-11-24T13:15",
      draft: "true"
    }
  end

  test "saving a draft creates the new patron, links existing patrons once and saves notes" do
    existing = patrons(:one)
    pending = {
      "0" => { patron_id: existing.id, first_name: "Ignored replacement" },
      "1" => { patron_id: existing.id },
      "2" => { known_as: "Synthetic alias", violation_summary: "  Synthetic policy note  " }
    }

    assert_difference({ "Incident.count" => 1, "Patron.count" => 1, "IncidentPatron.count" => 2, "ViolationSummary.count" => 1 }) do
      submit_pending(pending)
    end

    assert_response :success
    report = Incident.find_by!(title: @incident[:title])
    assert report.draft?
    assert report.patrons.exists?(existing.id)
    assert_not_equal "Ignored replacement", existing.reload.first_name
    assert_equal "Synthetic policy note", report.violation_summaries.sole.description
  end

  test "a validation failure leaves the incident and all provisional patrons unapplied" do
    pending = { "0" => { known_as: "Synthetic alias" }, "1" => { first_name: "" } }

    assert_no_difference ["Incident.count", "Patron.count", "IncidentPatron.count", "ViolationSummary.count"] do
      submit_pending(pending)
    end
    assert_response :success
    assert_includes response.body, "alias is required"
  end

  test "an unavailable existing patron rolls back the complete save" do
    pending = { "0" => { known_as: "Synthetic alias" }, "1" => { patron_id: -1 } }

    assert_no_difference ["Incident.count", "Patron.count", "IncidentPatron.count"] do
      submit_pending(pending)
    end
    assert_response :success
    assert_includes response.body, "A selected patron is no longer available"
  end

  private

  def submit_pending(pending)
    post incidents_save_path(format: :js), params: @incident.merge(pending_patrons: pending), xhr: true
  end
end
