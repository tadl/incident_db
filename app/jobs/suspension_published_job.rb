class SuspensionPublishedJob < ApplicationJob
    queue_as :default

    def perform(patron, incident, suspension)
        IncidentMailer.suspension_published(patron, incident, suspension).deliver
    end

end