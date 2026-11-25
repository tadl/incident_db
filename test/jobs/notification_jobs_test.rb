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

  test "legacy queued and current jobs deliver an issued suspension only once" do
    queued_job = SuspensionPublishedJob.new(@patron, @incident, @suspension).serialize
    queued_job["arguments"] = [@patron, @incident, @suspension].map do |record|
      { "_aj_globalid" => record.to_global_id(app: "rails7-base").to_s }
    end

    with_notification_addresses do
      assert_emails 1 do
        ActiveJob::Base.execute(queued_job)
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

  test "suspensions expire on the local end date and staff are notified the following day" do
    @suspension.update_columns(until: Date.new(2026, 6, 10))

    with_notification_addresses do
      travel_to Time.zone.local(2026, 6, 10, 21, 30) do
        assert_no_emails do
          SuspensionPublishedJob.perform_now(@suspension)
          CheckUnsentSuspensions.new.perform
          CheckExpiredSuspensions.new.perform
        end
      end

      travel_to Time.zone.local(2026, 6, 11, 0, 30) do
        assert_emails(1) { CheckExpiredSuspensions.new.perform }
        assert @suspension.reload.expired_email_sent?
        refute @suspension.issued_email_sent?
      end
    end
  end

  test "expiration notices use the override recipients or fall back to suspension staff" do
    @suspension.update_columns(until: Date.yesterday)

    with_notification_addresses do
      with_env("UNSUSPEND_EMAIL_TO" => " expired@example.org, , backup@example.org, EXPIRED@example.org ") do
        assert_emails(1) { CheckExpiredSuspensions.new.perform }
        assert_equal %w[expired@example.org backup@example.org], ActionMailer::Base.deliveries.last.smtp_envelope_to
        assert @suspension.reload.expired_email_sent?
      end

      @suspension.update_columns(expired_email_sent: false)
      assert_emails(1) { CheckExpiredSuspensions.new.perform }
      assert_equal ["suspensions@example.org"], ActionMailer::Base.deliveries.last.smtp_envelope_to
      assert @suspension.reload.expired_email_sent?
    end
  end

  test "expiration notices skip an empty recipient list without being marked sent" do
    @suspension.update_columns(until: Date.yesterday)

    with_notification_addresses do
      with_env("UNSUSPEND_EMAIL_TO" => "") do
        assert_no_emails { CheckExpiredSuspensions.new.perform }
        refute @suspension.reload.expired_email_sent?
      end

      with_env("CAN_SUSPEND" => nil) do
        assert_no_emails { CheckExpiredSuspensions.new.perform }
        refute @suspension.reload.expired_email_sent?
      end
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

  test "comment job passes comment details to the mailer" do
    comment = @incident.incident_comments.create!(user: users(:one), description: "Synthetic comment for delivery test")

    with_notification_addresses do
      assert_emails(1) { CommentAddedJob.perform_now(comment) }
      assert_includes ActionMailer::Base.deliveries.last.text_part.decoded, comment.description
    end
  end

  private

  def with_notification_addresses(&block)
    with_env("EMAIL_FROM" => "notices@example.org", "EMAIL_TO" => "reports@example.org",
      "COMMENT_EMAIL_TO" => "comments@example.org", "CAN_SUSPEND" => "suspensions@example.org",
      "UNSUSPEND_EMAIL_TO" => nil, &block)
  end
end
