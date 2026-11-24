class Oldreport < ApplicationRecord
  include PgSearch::Model

  has_many_attached :images do |attachment|
    attachment.variant :thumb, resize_to_fill: [250, 250]
  end

  pg_search_scope :search, against: [:title, :description, :narrative, :legacy_id, :patron_name, :submitted_by],
    using: { tsearch: { prefix: true } }

  def time_of_in_zone
    time_of&.strftime("at %l:%M %p")
  end

  def date_of_pretty
    date_of&.strftime("%m/%d/%Y")
  end

  def primary_pic
    images.first
  end

  def violations
    [a_violations, b_violations].compact_blank.map do |text|
      text.gsub(/(?<!\A)(?<![\s,])(?=[AB]\d+)/, ", ")
    end.join(", ")
  end

  def has_violations?
    a_violations.present? || b_violations.present?
  end
end
