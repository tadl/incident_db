class IncidentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def all
  end

  def new
    @incidents = Incident.all
    @date_time_today = DateTime.now.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y %H:%M")
    @incident = Incident.new
  end

  def edit
  end

  def save
    if params[:id]
        id = params[:id].to_i
        @incident = Incident.find(id)
    else
        @incident = Incident.new
    end
    if @incident
      @incident.assign_attributes(incident_params)
      @incident.date_of = params[:date_of].to_datetime
      if @incident.valid?
        @incident.save
        @updated = true
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
      params.permit(:title, :description, :location, :draft)
  end

end