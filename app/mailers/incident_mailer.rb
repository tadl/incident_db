require "active_storage/vips"

class IncidentMailer < ApplicationMailer
  INLINE_IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_SOURCE_IMAGE_BYTES = 10.megabytes
  MAX_SOURCE_IMAGE_PIXELS = 32_000_000
  MAX_INLINE_PHOTOS = 8
  MAX_INLINE_PHOTO_BYTES = 160.kilobytes
  MAX_INLINE_TOTAL_BYTES = 640.kilobytes

  def incident_published(incident)
    @incident = incident
    @record_url = incidents_view_url(id: incident.id)
    @incident_photo = photo_for(incident.images.first)
    @patron_entries = incident.patrons.includes(
      :violations, :violation_summaries, :images_attachments, suspensions: :incident
    ).map { |patron| [patron, photo_for(patron.images.first)] }

    mail(to: ENV["EMAIL_TO"], subject: "New incident report")
  end

  def suspension_published(suspension)
    set_suspension_details(suspension)
    @letter_url = private_attachment_url(suspension.letter.attachment) if suspension.letter.attached?

    mail(to: ENV["EMAIL_TO"], subject: "New suspension")
  end

  def suspension_expired(suspension)
    set_suspension_details(suspension)

    mail(to: ENV["EMAIL_TO"], subject: "Suspension expired")
  end

  def comment_added(comment)
    @comment = comment
    anchor = ActionView::RecordIdentifier.dom_id(comment, :entry)

    if comment.is_a?(IncidentComment)
      @record_label = "incident report"
      @record_name = comment.incident.title
      @record_url = incidents_view_url(id: comment.incident_id, anchor: anchor)
      subject = "New incident comment"
    else
      @record_label = "patron record"
      @record_name = comment.patron.full_name(show_call_911: false)
      @record_url = patrons_view_url(id: comment.patron_id, anchor: anchor)
      subject = "New patron comment"
    end

    mail(to: ENV["COMMENT_EMAIL_TO"], subject: subject)
  end

  private

  def set_suspension_details(suspension)
    @suspension = suspension
    @incident = suspension.incident
    @patron = suspension.patron
    @patron_photo = photo_for(@patron.images.first)
  end

  def photo_for(attachment)
    return unless attachment

    { url: private_attachment_url(attachment), inline_url: inline_thumbnail(attachment) }
  end

  def inline_thumbnail(attachment)
    return unless ActiveStorage::VIPS_AVAILABLE && attachment.variable?

    @inline_photo_attempts ||= 0
    @inline_photo_bytes ||= 0
    return if @inline_photo_attempts >= MAX_INLINE_PHOTOS

    byte_limit = [MAX_INLINE_PHOTO_BYTES, MAX_INLINE_TOTAL_BYTES - @inline_photo_bytes].min
    return if byte_limit <= 0

    @inline_photo_attempts += 1
    variation = attachment.variant(:thumb).variation
    return unless INLINE_IMAGE_TYPES.include?(variation.content_type)

    bytes = read_thumbnail(attachment.blob, variation, byte_limit)
    return if bytes.blank? || bytes.bytesize > byte_limit

    filename = "staff-photo-#{@inline_photo_attempts}.#{variation.format}"
    attachments.inline[filename] = { mime_type: variation.content_type, content: bytes }
    @inline_photo_bytes += bytes.bytesize

    attachments[filename].url
  rescue ActiveStorage::Error, ImageProcessing::Error, Vips::Error, SystemCallError, IOError, ArgumentError, KeyError
    # A missing or invalid photo must not delay a staff notice. The authenticated
    # original link remains available when the stored file can be repaired.
    nil
  end

  def read_thumbnail(blob, variation, byte_limit)
    # All configured services use disk. Render the existing thumbnail variation
    # without creating a variant record inside a suspension delivery transaction.
    File.open(blob.service.path_for(blob.key), "rb") do |source|
      return unless source.size.between?(1, MAX_SOURCE_IMAGE_BYTES)
      return unless INLINE_IMAGE_TYPES.include?(Marcel::MimeType.for(source))

      source.rewind

      image = Vips::Image.new_from_file(source.path, access: :sequential)
      return if image.width * image.height > MAX_SOURCE_IMAGE_PIXELS

      variation.transform(source) { |thumbnail| thumbnail.read(byte_limit + 1) }
    end
  end
end
