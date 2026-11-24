require "test_helper"
require "base64"

class IncidentMailerTest < ActionMailer::TestCase
  PNG = Base64.strict_decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aKbkAAAAASUVORK5CYII=")

  setup do
    @incident = incidents(:one)
    @patron = patrons(:one)
    @user = users(:one)
    @incident.update!(created_by: @user.id, description: "First line\nSecond line <script>synthetic()</script>")
    @patron.update!(first_name: "Fixture", middle_name: nil, last_name: "Patron", known_as: nil)
    @incident.patrons << @patron
    @incident.violation_summaries.create!(patron: @patron, description: "Current policy note <svg>")
    violations(:one).update!(description: "A3 Historical policy entry")
    @suspension = suspensions(:one)
    @suspension.update!(until: Date.new(2026, 12, 3), call_police: true, letter_sent: false)
  end

  test "incident mail includes the report and patron details in both formats" do
    with_addresses do
      mail = IncidentMailer.incident_published(@incident)
      assert_envelope(mail, "New Incident: #{@incident.title} (##{@incident.id})")
      assert_mail_contains(mail, @incident.title, @incident.date_of_in_time_zone, @incident.location, @user.name,
        "First line", "Second line", "Fixture Patron", "Current policy note", "A3 Historical policy entry",
        "http://www.example.com/incidents/view?id=#{@incident.id}", "http://www.example.com/patrons/view?id=#{@patron.id}")
      assert_includes mail.html_part.decoded, "&lt;script&gt;"
      assert_includes mail.html_part.decoded, "&lt;svg&gt;"
      refute_match(/<script|<svg/i, mail.html_part.decoded)
      assert_includes mail.text_part.decoded, "<script>synthetic()</script>"
    end
  end

  test "a repeated incident title does not reuse the subject" do
    title = "Synthetic \r\nincident title"
    @incident.update!(title: title)
    other = incidents(:two)
    other.update!(title: title)

    with_addresses do
      assert_envelope(IncidentMailer.incident_published(@incident), "New Incident: Synthetic incident title (##{@incident.id})")
      assert_envelope(IncidentMailer.incident_published(other), "New Incident: Synthetic incident title (##{other.id})")
    end
  end

  test "long incident titles leave room for the report number and mail encoding" do
    @incident.update!(title: "🧪" * 500)

    with_addresses do
      mail = IncidentMailer.incident_published(@incident)
      assert_match(/\ANew Incident: 🧪+… \(##{@incident.id}\)\z/, mail.subject)
      headers = mail.encoded.split("\r\n\r\n", 2).first
      assert_operator headers.lines(chomp: true).map(&:bytesize).max, :<=, 998
    end
  end

  test "incident and patron thumbnails are inline CID images with protected original links" do
    incident_image = attach_image(@incident)
    patron_image = attach_image(@patron)

    with_addresses do
      mail = IncidentMailer.incident_published(@incident)
      assert_equal 2, mail.attachments.size
      assert_mail_contains(mail,
        "http://www.example.com/attachments/#{incident_image.id}",
        "http://www.example.com/attachments/#{patron_image.id}")
      mail.attachments.each do |image|
        assert image.inline?
        assert_equal "image/png", image.mime_type
        assert_includes mail.html_part.decoded, %(src="#{image.url}")
        assert_operator image.body.decoded.bytesize, :<=, IncidentMailer::MAX_INLINE_PHOTO_BYTES
        assert_match(/\Astaff-photo-\d+\.png\z/, image.filename)
      end
      refute_includes mail.html_part.decoded, "/rails/active_storage"
      refute_includes mail.text_part.decoded, "cid:"
      refute_includes mail.encoded, "synthetic-private-filename"
    end
  end

  test "missing and invalid images leave original links and do not abort rendering" do
    incident_image = attach_image(@incident)
    incident_image.blob.service.delete(incident_image.blob.key)
    patron_image = attach_image(@patron, bytes: PNG.byteslice(0, 16))

    with_addresses do
      mail = IncidentMailer.incident_published(@incident)
      assert_empty mail.attachments
      assert_mail_contains(mail, @incident.title,
        "http://www.example.com/attachments/#{incident_image.id}",
        "http://www.example.com/attachments/#{patron_image.id}")
      refute_includes mail.html_part.decoded, "<img"
    end
  end

  test "the inline image count is bounded while every patron keeps the original link" do
    report_image = attach_image(@incident)
    last_image = nil
    IncidentMailer::MAX_INLINE_PHOTOS.times do |index|
      patron = @incident.patrons.create!(known_as: "Synthetic photo fixture #{index}")
      patron.images.attach(report_image.blob)
      last_image = patron.images.first
    end

    with_addresses do
      assert_no_difference "ActiveStorage::VariantRecord.count" do
        mail = IncidentMailer.incident_published(@incident).message
        assert_equal IncidentMailer::MAX_INLINE_PHOTOS, mail.attachments.size
        assert_operator mail.attachments.sum { |image| image.body.decoded.bytesize }, :<=, IncidentMailer::MAX_INLINE_TOTAL_BYTES
        assert_mail_contains(mail, "http://www.example.com/attachments/#{last_image.id}")
      end
    end
  end

  test "new suspension uses the specific end date, emergency instruction and policy details" do
    photo = attach_image(@patron)
    @suspension.letter.attach(io: StringIO.new("%PDF-1.4\n%%EOF\n"), filename: "synthetic-letter.pdf", content_type: "application/pdf")
    other = incidents(:two)
    other.update!(published: true)
    @patron.suspensions.create!(incident: other, until: Date.new(2026, 12, 20))

    with_addresses do
      mail = IncidentMailer.suspension_published(@suspension)
      assert_envelope(mail, "New suspension ##{@suspension.id}")
      assert_mail_contains(mail, "Fixture Patron", "12/03/2026", "Call 911 immediately if seen on library property.",
        "Current policy note", "A3 Historical policy entry", "Suspension letter has not been mailed.",
        "http://www.example.com/incidents/view?id=#{@incident.id}", "http://www.example.com/patrons/view?id=#{@patron.id}",
        "http://www.example.com/attachments/#{photo.id}", "http://www.example.com/attachments/#{@suspension.letter.id}")
      assert_equal 1, mail.attachments.size
      assert_includes mail.html_part.decoded, %(src="#{mail.attachments.first.url}")
      refute_includes mail.text_part.decoded, "12/20/2026"
    end
  end

  test "suspension expiration identifies the patron, date and related records" do
    photo = attach_image(@patron)

    with_addresses do
      mail = IncidentMailer.suspension_expired(@suspension)
      assert_envelope(mail, "Suspension expired ##{@suspension.id}")
      assert_mail_contains(mail, "Fixture Patron", "12/03/2026",
        "http://www.example.com/incidents/view?id=#{@incident.id}", "http://www.example.com/patrons/view?id=#{@patron.id}",
        "http://www.example.com/attachments/#{photo.id}")
      assert_equal 1, mail.attachments.size
      assert_includes mail.html_part.decoded, %(src="#{mail.attachments.first.url}")
    end
  end

  test "incident and patron comment notices include author, time, text and the entry link" do
    incident_comment = @incident.incident_comments.create!(user: @user, description: "Synthetic incident note")
    patron_comment = @patron.patron_comments.create!(user: @user, description: "Synthetic patron note <b>literal text</b>")

    with_addresses do
      mail = IncidentMailer.comment_added(incident_comment)
      assert_envelope(mail, "New incident comment ##{incident_comment.id}", "comments@example.org")
      assert_mail_contains(mail, @incident.title, @user.name, incident_comment.posted_on, incident_comment.description,
        "http://www.example.com/incidents/view?id=#{@incident.id}#entry_incident_comment_#{incident_comment.id}")

      mail = IncidentMailer.comment_added(patron_comment)
      assert_envelope(mail, "New patron comment ##{patron_comment.id}", "comments@example.org")
      assert_mail_contains(mail, "Fixture Patron", @user.name, patron_comment.posted_on, "Synthetic patron note",
        "http://www.example.com/patrons/view?id=#{@patron.id}#entry_patron_comment_#{patron_comment.id}")
      assert_includes mail.html_part.decoded, "&lt;b&gt;literal text&lt;/b&gt;"
      refute_includes mail.html_part.decoded, "<b>literal text</b>"
      assert_includes mail.text_part.decoded, patron_comment.description
    end
  end

  private

  def attach_image(record, bytes: PNG)
    record.images.attach(io: StringIO.new(bytes), filename: "synthetic-private-filename.png",
      content_type: "image/png", identify: false)
    record.images.last
  end

  def with_addresses(&block)
    with_env("EMAIL_FROM" => "notices@example.org", "EMAIL_TO" => "reports@example.org",
      "COMMENT_EMAIL_TO" => "comments@example.org", &block)
  end

  def assert_envelope(mail, subject, recipient = "reports@example.org")
    assert_equal subject, mail.subject
    assert_equal [recipient], mail.to
    assert_equal [recipient], mail.smtp_envelope_to
    assert_equal ["notices@example.org"], mail.from
    assert_empty Array(mail.cc)
    assert_empty Array(mail.bcc)
  end

  def assert_mail_contains(mail, *values)
    values.each do |value|
      assert_includes mail.html_part.decoded, value
      assert_includes mail.text_part.decoded, value
    end
  end
end
