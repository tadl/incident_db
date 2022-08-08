class Violation < ApplicationRecord
  belongs_to :patron, touch: true
  belongs_to :incident, touch: true
  validates :description, uniqueness: { scope: [:patron_id, :incident_id], message: 'Patron already has this violation type associated with this incident'  }
  validates :patron_id, uniqueness: { scope: [:incident_id, :description] }
end
