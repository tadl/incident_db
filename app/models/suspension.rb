class Suspension < ApplicationRecord
  belongs_to :patron
  belongs_to :incident
  validates :patron_id, uniqueness: { scope: [:incident_id] }
  has_one_attached :letter
  validates :letter, blob: { content_type: ['application/pdf'], size_range: 1..(5.megabytes) }

end
