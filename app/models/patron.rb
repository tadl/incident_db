class Patron < ApplicationRecord
  include PgSearch::Model

  has_many :patron_comments, dependent: :destroy
  has_many :incident_patrons, dependent: :destroy
  has_many :incidents, through: :incident_patrons
  has_many :violations, dependent: :destroy
  has_many :violation_summaries, dependent: :destroy
  has_many :suspensions, dependent: :destroy

  has_many_attached :images do |attachment|
    attachment.variant :thumb, resize_to_fill: [250, 250]
  end

  validates :images, blob: { content_type: ["image/png", "image/jpg", "image/jpeg"], size_range: 1..10.megabytes }
  validate :at_least_one_name

  pg_search_scope :search_by_name_alias_description,
    against: [:first_name, :last_name, :middle_name, :known_as, :description],
    associated_against: { patron_comments: :description },
    using: { tsearch: { prefix: true } }

  scope :unknown_name, -> {
    where("COALESCE(TRIM(first_name), '') = '' AND COALESCE(TRIM(middle_name), '') = '' AND COALESCE(TRIM(last_name), '') = ''")
  }

  def self.currently_suspended(call_911: false)
    published = Suspension.published.active
    expiration_dates = published.group(:patron_id).select(:patron_id, "MAX(suspensions.until) AS expires_on")
    patrons = joins("INNER JOIN (#{expiration_dates.to_sql}) AS active_suspensions ON active_suspensions.patron_id = patrons.id")
    patrons = patrons.where(id: published.where(call_police: true).select(:patron_id)) if call_911
    patrons.order("active_suspensions.expires_on ASC", :id)
  end

  def full_name(show_call_911: true)
    name = [first_name, middle_name, last_name].compact_blank.join(" ")
    name = [name.presence, ("AKA: #{known_as}" if known_as.present?)].compact.join(" ")
    show_call_911 && call_911? ? "#{name} (Call 911 immediately)" : name
  end

  def call_911?
    active_suspensions.any?(&:call_police?)
  end

  def unknown_name
    first_name.blank? && middle_name.blank? && last_name.blank?
  end

  def suspension_for(incident_id)
    if suspensions.loaded?
      suspensions.find { |suspension| suspension.incident_id == incident_id }
    else
      suspensions.find_by(incident_id: incident_id)
    end
  end

  def suspension_for_details(incident_id)
    suspension = suspension_for(incident_id)
    message = [suspension.until ? "#{suspension.until.strftime('%m/%d/%Y')}." : "End date unavailable."]
    message << "Please call 911 immediately if seen on property." if suspension.call_police?
    message << (suspension.letter_sent? ? "Letter has been mailed." : "Letter has not been mailed.") unless suspension.letter_sent.nil?
    message.join(" ")
  end

  def suspension_for_letter(incident_id)
    letter = suspension_for(incident_id)&.letter
    letter if letter&.attached?
  end

  def full_address
    [address, city, state, zip].compact_blank.join(" ")
  end

  def is_suspended
    active_suspensions.any?
  end

  def suspended_until
    active_suspensions.map(&:until).max&.strftime("%m/%d/%Y")
  end

  def published_incidents
    incidents.where(published: true).order(date_of: :desc, id: :desc)
  end

  def violation_summary_for(incident_id)
    if violation_summaries.loaded?
      violation_summaries.find { |summary| summary.incident_id == incident_id }
    else
      violation_summaries.find_by(incident_id: incident_id)
    end
  end

  def historical_violations_for(incident_id)
    entries = if violations.loaded?
      violations.select { |violation| violation.incident_id == incident_id }
    else
      violations.where(incident_id: incident_id)
    end
    entries.filter_map { |violation| violation.description.presence }.reject { |description| description == "None" }
  end

  private

  def at_least_one_name
    errors.add(:first_name, "or alias is required") if unknown_name && known_as.blank?
  end

  def active_suspensions
    if suspensions.loaded?
      suspensions.select { |suspension| suspension.until && suspension.until > Date.current && suspension.incident.published? }
    else
      suspensions.published.active.to_a
    end
  end
end
