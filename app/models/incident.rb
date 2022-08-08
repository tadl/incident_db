class Incident < ApplicationRecord
    has_many :violations
    has_many :patrons, through: :violations
    has_many_attached :images do |attachable|
        attachable.variant :thumb, resize_to_fill: [250, 250]
    end
    
    validates :location, presence: { message: 'Location required' }, allow_blank: false
    validates :date_of, presence: { message: 'Date and Time of Incident Required' }, allow_blank: false
    validates :title, presence: { message: 'Title required'}, allow_blank: false
    validates :title, uniqueness: { scope: [:date_of], message: 'An incident with this title has already been submitted for this time.'  }
    validates :description, presence: { message: 'Description required' }, allow_blank: false
    validates :description, uniqueness: { message: 'An incident type with this description already exisits'}

    def created_by_name
        user = User.find(self.created_by)
        return user.name
    end

    def last_edit_by_name
        user = User.find(self.last_edit_by)
        return user.name
    end

    def date_of_in_time_zone
        return self.date_of.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y at %l:%M %p")
    end

    def updated_at_in_time_zone
        return self.updated_at.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y at %l:%M %p")
    end

    def published_on_in_time_zone
        return self.published_on.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y at %l:%M %p")
    end
end