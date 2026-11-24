class IncidentMailerJob < ApplicationJob
  queue_as :default

  def perform(incident)
    return unless IncidentMailer.perform_deliveries && incident.reload.published?

    IncidentMailer.incident_published(incident).deliver_now
  end
end
