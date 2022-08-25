class IncidentMailerJob < ApplicationJob
    queue_as :default

    def perform(incident)
        IncidentMailer.incident_published(incident).deliver
    end

end