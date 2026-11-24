class SuspensionPublishedJob < ApplicationJob
  queue_as :default

  # Older enqueued jobs pass patron, incident, and suspension.
  def perform(suspension, _incident = nil, legacy_suspension = nil)
    return unless IncidentMailer.perform_deliveries

    suspension = legacy_suspension || suspension
    suspension.with_lock do
      next if suspension.issued_email_sent? || !suspension.until || suspension.until <= Date.current
      next unless suspension.incident&.published? && suspension.patron

      IncidentMailer.suspension_published(suspension.incident).deliver_now
      suspension.update_columns(issued_email_sent: true)
    end
  end
end
