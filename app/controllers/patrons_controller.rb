class PatronsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def save
    if params[:id] && params[:id] != ''
      id = param[:id].to_i
      @patron = Patron.find(id)
    else
      @patron = Patron.new
    end
    @patron.assign_attributes(patron_params)
    @patron.save
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
  end

  def list
  end

  def show
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

  private

  def patron_params
    params.permit(:first_name, :middle_name, :last_name, :no_name, :no_address, :city, :state, :zip, :alias, :description, :notes, :card_number)
  end

end
