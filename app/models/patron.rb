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
    validate :at_least_one_name

    def at_least_one_name
        if (first_name.blank? && middle_name.blank? && last_name.blank? && known_as.blank?)
            errors.add(:first_name, :blank, message: 'Must include a name or alias')
        end
    end

    def full_name
        full_name = ''
        full_name += self.first_name if self.first_name
        full_name += ' ' + self.middle_name if self.middle_name
        full_name += ' ' + self.last_name if self.last_name
        full_name += ' AKA: ' + self.known_as if self.known_as && self.known_as != ''
        return full_name
    end

    def violations_from_incident(incident_id)
        self.violations.where(incident_id: incident_id)
    end

    def unique_incidents
    #     unique_incident_ids = []
    #     unique_incidents = []
    #     self.incidents.each do |i|
    #         if  unique_incident_ids.include? (i.id)
    #         else
    #             unique_incident_ids.push(i.id)
    #             unique_incidents.push(i)
    #         end
    #     end
    #     if unique_incidents.size >= 1
    #         return unique_incidents
    #    else
    #         return
    #    end
        return self.incidents
    end
end
