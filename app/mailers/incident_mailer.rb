class IncidentMailer < ApplicationMailer
    default from: ENV['EMAIL_FROM']

    def incident_published(incident)
        @incident = incident
        mail to: ENV['EMAIL_TO'], subject: ('New Incident: ' + @incident.title)
    end

    def suspension_published(patron, incident, suspension)
        @patron = patron
        @incident = incident
        @suspension = suspension
        mail to: ENV['EMAIL_TO'], subject: ('New Suspension: ' + @patron.full_name + ', Suspended Until ' + @patron.suspended_until)
    end

    def suspension_expired(patron)
        @patron = patron
        mail to: ENV['EMAIL_TO'], subject: ('Suspension Expired: ' + @patron.full_name)
    end

    def comment_added(comment, type, value)
        @comment = comment
        @type = type
        @value = value
        @user = User.find(@comment.user_id)
        mail to: ENV['COMMENT_EMAIL_TO'], subject: ('Incident Report System: New ' + @type.capitalize + ' Comment')
    end
        


end
