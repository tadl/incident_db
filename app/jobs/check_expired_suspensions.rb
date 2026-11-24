class CheckExpiredSuspensions
  include Sidekiq::Job

  def perform
    return unless IncidentMailer.perform_deliveries

    expiration_date = Date.yesterday
    Suspension.published.where(until: expiration_date, expired_email_sent: [false, nil]).includes(:patron).find_each do |suspension|
      deliver_if_latest(suspension, expiration_date)
    end
  end

  private

  def deliver_if_latest(suspension, expiration_date)
    patron = suspension.patron
    patron&.with_lock do
      latest = patron.suspensions.published.where.not(until: nil).order(until: :desc, id: :desc).first
      next unless latest&.id == suspension.id

      latest.with_lock do
        next if latest.expired_email_sent? || latest.until != expiration_date || !latest.incident&.published?

        IncidentMailer.suspension_expired(latest).deliver_now
        latest.update_columns(expired_email_sent: true)
      end
    end
  rescue ActiveRecord::RecordNotFound
    # The patron or suspension was removed after the scan.
  end
end
