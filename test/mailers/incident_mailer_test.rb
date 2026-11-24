require "test_helper"

class IncidentMailerTest < ActionMailer::TestCase
  test "staff notifications contain generic subjects and only authenticated record links" do
    incident = Incident.new(id: 101, title: "Synthetic private report title", description: "Synthetic private incident narrative")
    patron = Patron.new(id: 202, first_name: "Synthetic", last_name: "Private Person")

    with_env("EMAIL_FROM" => "notices@example.org", "EMAIL_TO" => "reports@example.org", "COMMENT_EMAIL_TO" => "comments@example.org") do
      notices = [
        [IncidentMailer.incident_published(incident), "New incident report", "reports@example.org", "/incidents/view?id=101"],
        [IncidentMailer.suspension_published(incident), "New suspension", "reports@example.org", "/incidents/view?id=101"],
        [IncidentMailer.suspension_expired(patron), "Suspension expired", "reports@example.org", "/patrons/view?id=202"],
        [IncidentMailer.comment_added(incident), "New incident comment", "comments@example.org", "/incidents/view?id=101"],
        [IncidentMailer.comment_added(patron), "New patron comment", "comments@example.org", "/patrons/view?id=202"]
      ]

      notices.each do |message, subject, recipient, path|
        assert_equal subject, message.subject
        assert_equal [recipient], message.to
        assert_equal ["notices@example.org"], message.from
        url = "http://www.example.com#{path}"
        assert_includes message.html_part.decoded, %(href="#{url}")
        assert_includes message.text_part.decoded, url
        refute_includes message.html_part.decoded, "<img"
        refute_includes message.body.encoded, "Synthetic"
        refute_includes message.body.encoded, "Private"
      end
    end
  end
end
