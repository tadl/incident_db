class PatronsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def save
    if params[:patron_id] && params[:patron_id] != ''
      @patron = Patron.find(params[:patron_id])
      @edit = true
    else
      @patron = Patron.new
    end
    @patron.assign_attributes(patron_params)
    @patron.images.attach(params[:images])
    if @patron.valid?
      @patron.save
      if params[:incident_id] && params[:incident_id].to_i != 0
        @incident = Incident.find(params[:incident_id].to_i)
        if @incident
          violation = Violation.new
          violation.patron_id = @patron.id
          violation.incident_id = @incident.id
          violation.description = 'None'
          violation.save
        end
      else
        @editing_without_incident = true
      end
    else
      @error = true
    end
    respond_to do |format|
      format.js
    end
  end

  def add_existing_to_incident
    @patron = Patron.find(params[:patron_id])
    @incident = Incident.find(params[:incident_id].to_i)
    if @incident
      violation = Violation.new
      violation.patron_id = @patron.id
      violation.incident_id = @incident.id
      violation.description = 'None'
      violation.save
    end
    respond_to do |format|
      format.js
    end
  end

  def edit
    @patron = Patron.find(params[:patron_id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def list
  end

  def view
    @patron = Patron.find(params[:id])
  end

  def load_violation_modal
    if params[:track] == 'A'
      @violations = a_rules
    end
    if params[:track] == 'B'
      @violations = b_rules
    end
    @patron_id = params[:patron_id]
    respond_to do |format|
      format.js
    end
  end

  def save_violations
    @violation_ids = params[:violation_ids]
    @patron = Patron.find(params[:patron_id].to_i)
    @incident = Incident.find(params[:incident_id].to_i)
    if !@violation_ids.nil?
      @violation_ids.each do |v|
        violation = Violation.new
        violation.patron_id = @patron.id
        violation.incident_id = @incident.id
        rule = Rule.find(v)
        violation.description = rule.violation_format
        violation.save
      end
    end
    @violations = Violation.where(patron_id: @patron.id, incident_id:@incident.id).order('description DESC')
    respond_to do |format|
      format.js
    end
  end

  def remove_violation
    violation = Violation.find(params[:violation_id].to_i)
    violation.destroy
    @patron = Patron.find(params[:patron_id].to_i)
    @incident = Incident.find(params[:incident_id].to_i)
    @violations = Violation.where(patron_id: @patron.id, incident_id:@incident.id).order('description DESC')
    respond_to do |format|
      format.js
    end
  end

  def remove_patron_from_incident
    @patron_id = params[:patron_id]
    @incident_id = params[:incident_id]
    violations = Violation.where(patron_id: @patron_id, incident_id:@incident_id)
    violations.each do |v|
      v.destroy
    end
    respond_to do |format|
      format.js
    end
  end

  def delete_image
    @image = ActiveStorage::Attachment.find_by(id: params[:image_id])
    @image.purge
    @patron = Patron.find(params[:patron_id])
    @incident = Incident.find(params[:incident_id])
    respond_to do |format|
      format.js
    end
  end

  def load_patron_search
    incidents = Incident.all.includes(:patrons, :violations).order('date_of DESC').first(20)
    @incident = Incident.find(params[:incident_id])
    @patrons = []
    incidents.each do |i|
      i.patrons.each do |p|
        unless p.incidents.exists?(@incident.id)
          @patrons.push(p)
        end
      end
    end
    @patrons = @patrons.uniq
    respond_to do |format|
      format.js
    end
  end

  def load_new_patron_form
    respond_to do |format|
      format.js
    end
  end

  def search
    all_patrons = Patron.search_by_name_alias_description(params[:query]).with_pg_search_rank.first(10)
    @incident = Incident.find(params[:incident_id])
    @patrons = []
    all_patrons.each do |p|
      unless p.incidents.exists?(@incident.id)
        @patrons.push(p)
      end
    end
    respond_to do |format|
      format.json {render :json => @patrons}
      format.js
    end
  end

  private

  def patron_params
    params.permit(:first_name, :middle_name, :last_name, :no_name, :no_address, :address, :city, :state, :zip, :known_as, :description, :notes, :card_number)
  end

end
