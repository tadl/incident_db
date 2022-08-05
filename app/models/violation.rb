class Violation < ApplicationRecord
    validates :description, uniqueness: { scope: [:patron_id, :incident_id], message: 'Patron already has this violation type associated with this incident'  }
end
