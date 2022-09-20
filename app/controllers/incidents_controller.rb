class IncidentsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!

  def all
    if params[:just_mine] == 'true'
      @title = 'My'
      @search_param = 'just_mine'
      @incidents = Incident.paginate(page: params[:page], per_page: 10).where(published: true, created_by: current_user.id).order(date_of: :desc)
    elsif params[:just_drafts] == 'true'
      @title = 'My Draft'
      @incidents = Incident.paginate(page: params[:page], per_page: 10).where(draft: true, created_by: current_user.id).order(date_of: :desc)
      @search_param = 'just_drafts'
    else
      @title = 'All'
      @incidents = Incident.paginate(page: params[:page], per_page: 10).where(published: true).order(date_of: :desc)
      @search_param = 'all'
    end
  end

  def view
    id = params[:id].to_i
    @incident = Incident.find(id)
    @comments = Comment.where(incident_id: id) 
  end

  def new
    @date_time_today = DateTime.now.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y,  %H:%M")
    @incident = Incident.new
  end

  def edit
    id = params[:id].to_i
    if current_user.can_edit_incident(id)
      @incident = Incident.find(id) 
    else
      redirect_back_or_to '/'
    end
  end

  def save
    if params[:incident_id] && params[:incident_id] != ''
      if current_user.can_edit_incident(params[:incident_id])
        @incident = Incident.find(params[:incident_id])     
        @incident.last_edit_by = current_user.id
        unless params[:draft] == 'true'
          if @incident.draft == true
            @incident.draft = false
            @incident.published_on = DateTime.now
            @incident.published = true
           @new_publish = true
          end
        end
        puts "Goooooott hereeeee"
      else
        redirect_back_or_to '/'
      end
    else
      @incident = Incident.new
      @incident.created_by = current_user.id
      unless params[:draft] == 'true'
        @incident.published_on = DateTime.now
        @incident.published = true
        @new_publish = true
      end
    end
    if @incident
      @incident.assign_attributes(incident_params)
      @incident.date_of = params[:date_of].to_datetime
      @incident.images.attach(params[:images])
      if @incident.valid?
        @incident.save
        @updated = true
        if @new_publish == true
          IncidentMailerJob.perform_later(@incident)
        end
        if params[:add_patron] == "true"
          @add_patron = true
        else
          @add_patron = false
        end
      else
        @updated = false
      end
    else
        @updated = false 
    end
    respond_to do |format|
        format.js
    end
  end

  def delete_image
    @image = ActiveStorage::Attachment.find_by(id: params[:image_id])
    @image.purge
    @incident = Incident.find(params[:incident_id])
    
    respond_to do |format|
      format.js
    end
  end

  def search
    @query = params[:query]
    @incidents = Incident.paginate(page: params[:page], per_page: 5).where(published: true).search(params[:query])
    respond_to do |format|
      format.html
      format.json {render :json => @incidents}
    end
  end

  def delete_incident
    @incident = Incident.find(params[:id])
    if current_user.can_delete_this_incident(@incident)
      @violations = Violation.where(incident_id: @incident.id)
      @violations.each do |v|
        v.destroy
      end
      @suspensions = Suspension.where(incident_id: @incident.id)
      @suspensions.each do |s|
        s.destroy
      end
      @comments = Comment.where(incident_id: @incident.id)
      @comments.each do |c|
        c.destroy
      end
      @incident.destroy
    else
      @error = 'You do not have permission to delete this incident'
    end
    respond_to do |format|
      format.js
    end
  end

  private

  def incident_params
      params.permit(:title, :description, :location, :draft, :no_patrons)
  end

end