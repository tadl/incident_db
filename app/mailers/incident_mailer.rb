class IncidentMailer < ApplicationMailer
    default from: ENV['EMAIL_FROM']

    def incident_published(incident)
        @incident = incident
        mail to: ENV['EMAIL_TO'], subject: ('New Incident: ' + @incident.title)
    end

end
