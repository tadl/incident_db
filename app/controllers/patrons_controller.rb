class PatronsController < ApplicationController
  before_action :require_script_request, except: [:edit, :list, :view, :search]
  before_action :load_editable_incident, only: [:add_existing_to_incident, :remove_patron_from_incident, :load_patron_search, :load_new_patron_form]
  before_action :load_optional_editable_incident, only: [:save, :edit, :delete_image, :search]
  before_action :load_suspension_incident, only: [:load_suspension_form, :save_suspension, :delete_suspension, :delete_letter]

  def save
    @edit = params[:patron_id].present?
    @editing_without_incident = @incident.nil?
    @patron = @edit ? patron_scope.find(params[:patron_id]) : Patron.new
    if @incident
      @incident.with_lock do
        save_patron
        @incident.incident_patrons.find_or_create_by!(patron: @patron) unless @edit
      end
    else
      @patron.with_lock { save_patron }
    end
    render :save
  rescue ActiveRecord::RecordInvalid => error
    @errors = error.record.errors.full_messages
    render :save
  end

  def add_existing_to_incident
    @patron = Patron.find(params[:patron_id])
    @incident.with_lock { @incident.incident_patrons.find_or_create_by!(patron: @patron) }
  end

  def edit
    @patron = patron_scope.find(params[:patron_id])
  end

  def list
    if params[:suspended] == "true"
      call_911 = params[:call_911] == "true"
      @title = call_911 ? "Currently Suspended Patrons - Call 911 If Seen on Property" : "Currently Suspended Patrons"
      patrons = Patron.currently_suspended(call_911: call_911)
    else
      @title = "All Patrons"
      patrons = Patron.order(created_at: :desc, id: :desc)
    end
    @patrons = patrons.includes(suspensions: :incident).paginate(page: params[:page], per_page: 10)
  end

  def view
    @patron = Patron.includes(suspensions: :incident).find(params[:id])
  end

  def remove_patron_from_incident
    @incident.with_lock do
      link = @incident.incident_patrons.find_by!(patron_id: params[:patron_id])
      @patron = link.patron
      suspensions = @patron.suspensions.where(incident: @incident)
      if !current_user.can_suspend && suspensions.exists?
        return head :forbidden
      end

      suspensions.destroy_all
      @patron.violation_summaries.where(incident: @incident).destroy_all
      @patron.violations.where(incident: @incident).destroy_all
      link.destroy!
    end
  end

  def delete_image
    @patron = patron_scope.find(params[:patron_id])
    @patron.images.attachments.find(params[:image_id]).purge_later
  end

  def delete_letter
    @incident.with_lock do
      @suspension = suspension_scope.find(params[:suspension_id])
      @suspension.letter.purge_later
    end
  end

  def load_patron_search
    recent_incidents = Incident.where(published: true).order(date_of: :desc, id: :desc).limit(20).select(:id)
    recent_patrons = IncidentPatron.where(incident_id: recent_incidents).select(:patron_id)
    @patrons = other_patrons.where(id: recent_patrons).order(updated_at: :desc, id: :desc).limit(5)
  end

  def load_new_patron_form
  end

  def load_suspension_form
    @suspension = suspension_scope.first_or_initialize
    @title = @suspension.persisted? ? "Editing Suspension" : "Creating New Suspension"
  end

  def save_suspension
    @incident.with_lock do
      @suspension = if params[:suspension_id].present?
        suspension_scope.find(params[:suspension_id])
      else
        suspension_scope.first_or_initialize
      end
      @new_suspension = @suspension.new_record?
      @suspension.assign_attributes(params.permit(:until, :call_police, :letter_sent))
      @suspension.letter.attach(params[:letter]) if params[:letter].is_a?(ActionDispatch::Http::UploadedFile)
      @suspension.save!
    end

    SuspensionPublishedJob.perform_later(@suspension) if @new_suspension && @incident.published?
    render :save_suspension
  rescue ActiveRecord::RecordInvalid => error
    @errors = error.record.errors.full_messages
    render :save_suspension
  end

  def delete_suspension
    @incident.with_lock { suspension_scope.find(params[:suspension_id]).destroy! }
  end

  def search
    @query = params[:query] if params[:query].is_a?(String)
    if @incident || (request.xhr? && request.format.js? && params[:pending_incident] == "true")
      candidates = @incident ? other_patrons : Patron.all
      @patrons = @query.present? ? candidates.search_by_name_alias_description(@query).limit(5) : Patron.none
    else
      @unknown_only = params[:unknown_only] == "true"
      patrons = @unknown_only ? Patron.unknown_name : Patron.all
      patrons = patrons.search_by_name_alias_description(@query) if @query.present?
      patrons = patrons.none unless @query.present? || @unknown_only
      @patrons = patrons.includes(suspensions: :incident).order(created_at: :desc, id: :desc).paginate(page: params[:page], per_page: 5)
    end
  end

  def delete_patron
    return head :forbidden unless current_user.is_super_admin

    @patron = Patron.find(params[:id])
    @patron.with_lock { @patron.destroy! }
  end

  private

  def require_script_request
    head :not_acceptable unless request.xhr? && request.format.js?
  end

  def load_editable_incident
    @incident = Incident.find(params[:incident_id])
    head :forbidden unless current_user.can_edit_incident(@incident)
  end

  def load_optional_editable_incident
    load_editable_incident if params[:incident_id].present?
  end

  def load_suspension_incident
    return head :forbidden unless current_user.can_suspend

    @incident = Incident.find(params[:incident_id])
    head :not_found unless current_user.can_view_incident(@incident)
  end

  def patron_scope
    @incident ? @incident.patrons : Patron
  end

  def other_patrons
    Patron.where.not(id: @incident.incident_patrons.select(:patron_id))
  end

  def suspension_scope
    @patron = @incident.patrons.find(params[:patron_id])
    @patron.suspensions.where(incident: @incident)
  end

  def save_patron
    @patron.assign_attributes(params.permit(*Patron::EDITABLE_ATTRIBUTES))
    images = Array(params[:images]).grep(ActionDispatch::Http::UploadedFile)
    @patron.images.attach(images) if images.any?
    @patron.save!
  end
end
