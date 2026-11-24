class Incident < ApplicationRecord
  include PgSearch::Model

  belongs_to :author, class_name: "User", foreign_key: :created_by, optional: true
  belongs_to :last_editor, class_name: "User", foreign_key: :last_edit_by, optional: true

  has_many :incident_comments, dependent: :destroy
  has_many :incident_patrons, dependent: :destroy
  has_many :patrons, through: :incident_patrons
  has_many :violations, dependent: :destroy
  has_many :violation_summaries, dependent: :destroy
  has_many :suspensions, dependent: :destroy

  has_many_attached :images do |attachment|
    attachment.variant :thumb, resize_to_fill: [250, 250]
  end

  enum :violation_format, { legacy: "legacy", summary: "summary" }, prefix: true

  validates :images, blob: { content_type: ["image/png", "image/jpg", "image/jpeg"], size_range: 1..10.megabytes }
  validates :title, :location, :date_of, :description, presence: true
  validates :title, uniqueness: { scope: :date_of, message: "has already been used for an incident at this time" }

  pg_search_scope :search, against: [:title, :description, :id], associated_against: {
    patrons: [:first_name, :last_name, :middle_name, :known_as, :description],
    violations: :description,
    violation_summaries: :description,
    incident_comments: :description
  }, using: { tsearch: { prefix: true } }

  def created_by_name
    author&.name || "Unknown staff member"
  end

  def last_edit_by_name
    last_editor&.name || "Unknown staff member"
  end

  def date_of_in_time_zone
    date_of&.strftime("%m/%d/%Y at %l:%M %p")
  end

  def date_of_in_time_zone_minus_time
    date_of&.strftime("%m/%d/%Y")
  end

  def updated_at_in_time_zone
    updated_at.strftime("%m/%d/%Y at %l:%M %p")
  end

  def published_on_in_time_zone
    published_on&.strftime("%m/%d/%Y at %l:%M %p")
  end

  def primary_pic
    images.first || patrons.lazy.filter_map { |patron| patron.images.first }.first
  end
end
