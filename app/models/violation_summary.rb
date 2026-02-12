class ViolationSummary < ApplicationRecord
  belongs_to :incident
  belongs_to :patron

  validates :description, presence: true
  validates :incident_id, uniqueness: { scope: :patron_id }
end