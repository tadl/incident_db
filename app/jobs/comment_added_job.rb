class CommentAddedJob < ApplicationJob
  queue_as :default

  def perform(comment)
    return unless IncidentMailer.perform_deliveries

    case comment.reload
    when IncidentComment
      incident = comment.incident
      IncidentMailer.comment_added(comment).deliver_now if incident&.published?
    when PatronComment
      patron = comment.patron
      IncidentMailer.comment_added(comment).deliver_now if patron
    end
  end
end
