class Patron < ApplicationRecord
    include PgSearch::Model
    pg_search_scope :search_by_name_alias_description, 
    against: [:first_name, :last_name, :middle_name, :alias, :description],
    using: {
      tsearch: {prefix: true}
    }
    has_many :violations
    has_many :incidents, through: :violations
    has_many_attached :images do |attachable|
        attachable.variant :thumb, resize_to_fill: [250, 250]
    end

    validates :images, blob: { content_type: ['image/png', 'image/jpg', 'image/jpeg'], size_range: 1..(5.megabytes) }

    def full_name
        if self.no_name == true
            return self.alias
        else
            full_name = first_name
            full_name += ' ' + middle_name if middle_name
            full_name += ' ' + last_name if last_name
            return full_name
        end
    end

    def violations_from_incident(incident_id)
        self.violations.where(incident_id: incident_id)
    end
end
