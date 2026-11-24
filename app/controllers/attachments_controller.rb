class AttachmentsController < ApplicationController
  INLINE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

  skip_before_action :authenticate_user!, only: :thumbnail
  before_action :require_staff_session, only: :thumbnail
  before_action :load_attachment
  rescue_from ActiveStorage::FileNotFoundError, ActionController::MissingFile, with: :missing_file

  def show
    blob = @attachment.blob
    inline = @attachment.name == "images" && INLINE_TYPES.include?(blob.content_type)
    serve_file(blob, inline: inline)
  end

  def thumbnail
    return head :not_found unless @attachment.name == "images" && @attachment.variable?

    serve_file(@attachment.variant(:thumb).processed, inline: true)
  end

  private

  def require_staff_session
    head :unauthorized unless current_user
  end

  def load_attachment
    @attachment = ActiveStorage::Attachment.find(params[:id])
    head :not_found unless permitted_attachment?
  end

  def permitted_attachment?
    case @attachment.record_type
    when "Incident"
      @attachment.name == "images" && @attachment.record && current_user.can_view_incident(@attachment.record)
    when "Patron", "Oldreport"
      @attachment.name == "images" && @attachment.record.present?
    when "Suspension"
      incident = @attachment.record&.incident
      @attachment.name == "letter" && incident && current_user.can_view_incident(incident)
    else
      false
    end
  end

  # The configured services are disks. Serve through Rails after authorization
  # without returning a separate link that could be shared outside the session.
  def serve_file(file, inline:)
    send_file file.service.path_for(file.key), filename: file.filename.to_s,
      type: inline ? file.content_type : "application/octet-stream",
      disposition: inline ? "inline" : "attachment"
  end

  def missing_file
    head :not_found
  end
end
