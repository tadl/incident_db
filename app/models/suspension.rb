class Suspension < ApplicationRecord
  belongs_to :patron
  belongs_to :incident

  has_one_attached :letter

  validates :patron_id, uniqueness: { scope: :incident_id }
  validates :until, presence: true
  validates :letter, blob: { content_type: ["application/pdf"], size_range: 1..5.megabytes }

  scope :published, -> { joins(:incident).where(incidents: { published: true }) }
  scope :active, -> { where(arel_table[:until].gt(Date.current)) }
end
