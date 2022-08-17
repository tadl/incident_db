class Suspension < ApplicationRecord
  belongs_to :patron
  belongs_to :incident
  validates :patron_id, uniqueness: { scope: [:incident_id] }
end
