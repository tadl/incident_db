class IncidentPatron < ApplicationRecord
  belongs_to :incident
  belongs_to :patron
end
