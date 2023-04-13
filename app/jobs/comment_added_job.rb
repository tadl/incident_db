class CommentAddedJob < ApplicationJob
    queue_as :default

    def perform(comment)
        if comment.kind_of?(IncidentComment)
            incident = Incident.find(comment.incident_id)
            type = 'incident'
            IncidentMailer.comment_added(comment, type, incident).deliver
        elsif comment.kind_of?(PatronComment)
            patron = Patron.find(comment.patron_id)
            type = 'patron'
            IncidentMailer.comment_added(comment, type, patron).deliver
        end
    end

end