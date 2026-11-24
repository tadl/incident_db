require "test_helper"
require "minitest/mock"

class NotificationJobsTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @incident = incidents(:one)
    @patron = patrons(:one)
    @suspension = suspensions(:one)
    @incident.update_columns(published: true)
    @suspension.update_columns(until: Date.current + 7.days)
  end

  test "published and scheduled jobs deliver an issued suspension only once" do
    with_notification_addresses do
      assert_emails 1 do
        SuspensionPublishedJob.perform_now(@patron, @incident, @suspension)
        CheckUnsentSuspensions.new.perform
        SuspensionPublishedJob.perform_now(@suspension)
      end
      assert @suspension.reload.issued_email_sent?
    end
  end

  test "scheduled job catches active suspensions and skips drafts and expired suspensions" do
    draft_suspension = suspensions(:two)
    draft_suspension.update_columns(until: Date.current + 7.days)
    draft_suspension.incident.update_columns(published: false)

    with_notification_addresses do
      assert_emails(1) { CheckUnsentSuspensions.new.perform }
      assert @suspension.reload.issued_email_sent?
      refute draft_suspension.reload.issued_email_sent?

      @suspension.update_columns(until: Date.yesterday, issued_email_sent: false)
      assert_no_emails { CheckUnsentSuspensions.new.perform }
      refute @suspension.reload.issued_email_sent?
    end
  end

  test "a delivery failure leaves the issued notice available for retry" do
    with_notification_addresses do
      unavailable = ->(*) { raise Net::SMTPServerBusy, "Temporary synthetic failure" }
      IncidentMailer.stub(:suspension_published, unavailable) do
        assert_raises(Net::SMTPServerBusy) { SuspensionPublishedJob.perform_now(@suspension) }
      end
      refute @suspension.reload.issued_email_sent?
      assert_emails(1) { CheckUnsentSuspensions.new.perform }
      assert @suspension.reload.issued_email_sent?
    end
  end

  test "expiration notice waits for a patron's latest published suspension and sends once" do
    @suspension.update_columns(until: Date.yesterday)
    newer = suspensions(:two)
    newer.incident.update_columns(published: true)
    newer.update_columns(patron_id: @patron.id, until: Date.current + 7.days)

    with_notification_addresses do
      assert_no_emails { CheckExpiredSuspensions.new.perform }
      refute @suspension.reload.expired_email_sent?

      newer.update_columns(until: Date.yesterday)
      assert_emails 1 do
        CheckExpiredSuspensions.new.perform
        CheckExpiredSuspensions.new.perform
      end
      assert_equal 1, @patron.suspensions.where(expired_email_sent: true).count
    end
  end

  test "jobs skip draft incidents and comments deleted while queued" do
    deleted_comment = IncidentComment.create!(incident: @incident, description: "Synthetic staff comment")
    serialized_job = CommentAddedJob.new(deleted_comment).serialize
    deleted_comment.destroy!
    @incident.update_columns(published: false)

    with_notification_addresses do
      assert_no_emails do
        ActiveJob::Base.execute(serialized_job)
        IncidentMailerJob.perform_now(@incident)
        CommentAddedJob.perform_now(IncidentComment.create!(incident: @incident, description: "Synthetic draft comment"))
      end
    end
  end

  private

  def with_notification_addresses(&block)
    with_env("EMAIL_FROM" => "notices@example.org", "EMAIL_TO" => "reports@example.org", "COMMENT_EMAIL_TO" => "comments@example.org", &block)
  end
end
