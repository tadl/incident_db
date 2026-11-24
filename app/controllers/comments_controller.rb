class CommentsController < ApplicationController
  before_action :load_parent
  before_action :load_owned_comment, only: [:update, :delete]

  def save
    comment = @comments.build(comment_params.merge(user: current_user))
    if comment.save
      CommentAddedJob.perform_later(comment) if !@parent.is_a?(Incident) || @parent.published?
      redirect_to parent_path(anchor: comment_anchor(comment)), status: :see_other
    else
      redirect_to parent_path, alert: comment.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def update
    if @comment.update(comment_params)
      redirect_to parent_path(anchor: comment_anchor(@comment)), status: :see_other
    else
      redirect_to parent_path, alert: @comment.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def delete
    @comment.destroy!
    redirect_to parent_path(anchor: "comments"), status: :see_other
  end

  private

  def load_parent
    case params[:comment_for]
    when "incident"
      @parent = Incident.find(params[:owner_id])
      return head :not_found unless current_user.can_view_incident(@parent)

      @comments = @parent.incident_comments
    when "patron"
      @parent = Patron.find(params[:owner_id])
      @comments = @parent.patron_comments
    else
      head :bad_request
    end
  end

  def load_owned_comment
    @comment = @comments.find(params[:id])
    head :forbidden unless current_user.my_comment(@comment)
  end

  def parent_path(anchor: nil)
    if @parent.is_a?(Incident)
      incidents_view_path(id: @parent.id, anchor:)
    else
      patrons_view_path(id: @parent.id, anchor:)
    end
  end

  def comment_anchor(comment)
    ActionView::RecordIdentifier.dom_id(comment, :entry)
  end

  def comment_params
    params.permit(:description)
  end
end
