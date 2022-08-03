class IncidentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def all
    @incidents = Incident.all.where(draft: false)
  end

  def view
    id = params[:id].to_i
    @incident = Incident.find(id) 
  end

  def new
    @date_time_today = DateTime.now.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y,  %H:%M")
    @incident = Incident.new
  end

  def edit
    id = params[:id].to_i
    @incident = Incident.find(id) 
  end

  def save
    if params[:id] && params[:id] != ''
      id = params[:id].to_i
      @incident = Incident.find(id)
      @incident.last_edit_by = current_user.id
      unless params[:draft] == 'true'
        if @incident.draft == true
          @incident.draft = false
          @incident.published_on = DateTime.now
          @incident.published = true
          @new_publish = true
        end
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
      if @incident.valid?
        @incident.save
        @updated = true
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

  private

  def incident_params
      params.permit(:title, :description, :location, :draft, :no_patrons)
  end

end