class Incident < ApplicationRecord
    include PgSearch::Model
    
    has_many :violations
    has_many :suspensions
    has_many :patrons, through: :violations
    has_many_attached :images do |attachable|
        attachable.variant :thumb, resize_to_fill: [250, 250]
    end

    validates :images, blob: { content_type: ['image/png', 'image/jpg', 'image/jpeg'], size_range: 1..(5.megabytes) }
    validates :location, presence: { message: 'Location required' }, allow_blank: false
    validates :date_of, presence: { message: 'Date and Time of Incident Required' }, allow_blank: false
    validates :title, presence: { message: 'Title required'}, allow_blank: false
    validates :title, uniqueness: { scope: [:date_of], message: 'An incident with this title has already been submitted for this time.'  }
    validates :description, presence: { message: 'Description required' }, allow_blank: false
    validates :description, uniqueness: { message: 'An incident type with this description already exisits'}

    pg_search_scope :search, against: [:title, :description], associated_against: {
        patrons: [:first_name, :last_name, :middle_name, :known_as, :description],
        violations: :description
      }

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
    
    def date_of_in_time_zone_minus_time
        return self.date_of.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y")
    end

    def updated_at_in_time_zone
        return self.updated_at.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y at %l:%M %p")
    end

    def published_on_in_time_zone
        return self.published_on.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y at %l:%M %p")
    end

    def primary_pic
        if self.images.size >= 1
            return self.images[0]
        elsif self.patrons
            patron_pics = []
            self.patrons.each do |p|
                if p.images[0]
                    patron_pics.push(p.images[0])
                end
            end
            if patron_pics[0]
                return patron_pics[0]
            end
        end
    end
end