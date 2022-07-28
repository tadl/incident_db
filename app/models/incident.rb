class Incident < ApplicationRecord
    validates :location, presence: { message: 'Location required' }, allow_blank: false
    validates :date_of, presence: { message: 'Date and Time of Incident Required' }, allow_blank: false
    validates :title, presence: { message: 'Title required'}, allow_blank: false
    validates :title, uniqueness: { scope: [:date_of], message: 'An incident with this title has already been submitted for this time.'  }
    validates :description, presence: { message: 'Description required' }, allow_blank: false
    validates :description, uniqueness: { message: 'An incident type with this description already exisits'}
end
