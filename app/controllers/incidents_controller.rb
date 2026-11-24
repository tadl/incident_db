class IncidentsController < ApplicationController
  before_action :require_script_request, only: [:save, :delete_image, :delete_incident]

  def all
    incidents = Incident.includes(:author, patrons: { suspensions: :incident }).order(date_of: :desc, id: :desc)

    if params[:just_mine] == "true"
      @title = "My"
      @search_param = "just_mine"
      incidents = incidents.where(published: true, created_by: current_user.id)
    elsif params[:just_drafts] == "true"
      @title = "My Draft"
      @search_param = "just_drafts"
      incidents = incidents.where(published: false, draft: true, created_by: current_user.id)
    else
      @title = "All"
      @search_param = "all"
      incidents = incidents.where(published: true)
    end

    @incidents = incidents.paginate(page: params[:page], per_page: 10)
  end

  def view
    @incident = Incident.find(params[:id])
    return head :not_found unless current_user.can_view_incident(@incident)
  end

  def new
    @incident = Incident.new(violation_format: :summary, date_of: Time.current)
  end

  def edit
    @incident = Incident.find(params[:id])
    return head :forbidden unless current_user.can_edit_incident(@incident)
  end

  def save
    if params[:incident_id].present?
      @incident = Incident.find(params[:incident_id])
      return head :forbidden unless current_user.can_edit_incident(@incident)

      @incident.with_lock { save_incident }
    else
      @incident = Incident.new(violation_format: :summary, created_by: current_user.id)
      Incident.transaction { save_incident }
    end

    @updated = true
    @add_patron = params[:add_patron] == "true"
    IncidentMailerJob.perform_later(@incident) if @new_publish
    render :save
  rescue ActiveRecord::RecordInvalid => error
    @errors = error.record.errors.full_messages
    render :save
  end

  def delete_image
    @incident = Incident.find(params[:incident_id])
    return head :forbidden unless current_user.can_edit_incident(@incident)

    @incident.images.attachments.find(params[:image_id]).purge_later
  end

  def search
    @query = params[:query] if params[:query].is_a?(String)
    incidents = Incident.where(published: true).includes(:author, patrons: { suspensions: :incident })
    incidents = @query.present? ? incidents.search(@query) : incidents.none
    @incidents = incidents.paginate(page: params[:page], per_page: 5)
  end

  def delete_incident
    @incident = Incident.find(params[:id])
    @incident.with_lock do
      return head :forbidden unless current_user.can_delete_this_incident(@incident)

      @incident.destroy!
    end
  end

  private

  def require_script_request
    head :not_acceptable unless request.xhr? && request.format.js?
  end

  def save_incident
    @incident.assign_attributes(params.permit(:title, :description, :location))
    @incident.last_edit_by = current_user.id if @incident.persisted?
    @incident.date_of = incident_date

    @new_publish = !@incident.published? && params[:draft] != "true"
    @incident.published_on = Time.current if @new_publish
    @incident.published = true if @new_publish
    @incident.draft = !@incident.published?

    images = Array(params[:images]).grep(ActionDispatch::Http::UploadedFile)
    @incident.images.attach(images) if images.any?
    @incident.save!
    save_violation_summaries
  end

  def incident_date
    value = params[:date_of]
    return unless value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}\z/)

    parsed = Time.zone.iso8601(value)
    return unless parsed.strftime("%Y-%m-%dT%H:%M") == value

    existing = @incident.date_of
    existing&.strftime("%Y-%m-%dT%H:%M") == value ? existing : parsed
  rescue ArgumentError
    nil
  end

  def save_violation_summaries
    descriptions = params[:violation_summaries]
    return unless descriptions.is_a?(ActionController::Parameters)

    patron_ids = @incident.incident_patrons.pluck(:patron_id).map(&:to_s)
    if (descriptions.keys - patron_ids).any?
      @incident.errors.add(:base, "A violation was submitted for a patron who is no longer linked to this incident")
      raise ActiveRecord::RecordInvalid, @incident
    end

    descriptions.each_pair do |patron_id, attributes|
      next unless attributes.is_a?(ActionController::Parameters) && attributes[:description].is_a?(String)

      summary = @incident.violation_summaries.find_or_initialize_by(patron_id: patron_id)
      description = attributes[:description].strip
      if description.present?
        summary.update!(description: description)
      elsif summary.persisted?
        summary.destroy!
      end
    end
  end
end
