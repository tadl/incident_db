class CommentsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def save
        if (params[:description] && params[:description] != '')
            if params[:comment_for] == 'incident'
                comment = IncidentComment.new
                comment.description = params[:description] 
                comment.incident_id = params[:id]
                comment.user_id = current_user.id
                comment.save!
                @comments = IncidentComment.where(incident_id: params[:id])
            elsif params[:comment_for] == 'patron'
                comment = PatronComment.new
                comment.description = params[:description] 
                comment.patron_id = params[:id]
                comment.user_id = current_user.id
                comment.save!
                @comments = PatronComment.where(patron_id: params[:id])
            else
                @error = 'Something went wrong. Please let IT know.'
            end
        else
            @error = 'Please enter your extra information in the box above'
        end
        @from = params[:comment_for]
        respond_to do |format|
            format.js
        end
    end

    def delete
        comment = Comment.find(params[:id])
        comment.destroy
        if params[:comment_for] == 'incident'
            @comments = IncidentComment.where(incident_id: params[:owner_id])
        elsif params[:comment_for] == 'patron'
            @comments = PatronComment.where(patron_id: params[:owner_id])
        end
        @owner_id = params[:owner_id]
        @from = params[:comment_for]
        respond_to do |format|
            format.js
        end
    end

    private

    def comment_params
        params.permit(:description)
    end

end