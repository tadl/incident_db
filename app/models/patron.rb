class Patron < ApplicationRecord
    include PgSearch::Model
    pg_search_scope :search_by_name_alias_description, 
    against: [:first_name, :last_name, :middle_name, :known_as, :description], associated_against: {
        patron_comments: :description
      },
    using: {
      tsearch: {prefix: true}
    }
    has_many :patron_comments
    has_many :violations
    has_many :suspensions
    has_many :incidents, through: :violations
    has_many_attached :images do |attachable|
        attachable.variant :thumb, resize_to_fill: [250, 250]
    end

    validates :images, blob: { content_type: ['image/png', 'image/jpg', 'image/jpeg'], size_range: 1..(10.megabytes) }
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

    def unknown_name
        if self.first_name.blank? && self.middle_name.blank? && self.last_name.blank?
            return true
        else
            return false
        end
    end

    def violations_from_incident(incident_id)
        self.violations.where(incident_id: incident_id)
    end

    def suspension_for(incident_id)
        self.suspensions.where(incident_id: incident_id).first
    end

    def suspension_for_details(incident_id)
        suspension = self.suspensions.where(incident_id: incident_id).first
        message = suspension.until.strftime("%m/%d/%Y") + '.'
        message += ' Please call 911 immediately if seen on property.' if suspension.call_police
        message += ' Letter has been mailed.' if suspension.letter_sent
        message += ' Letter has not been mailed.' if suspension.letter_sent == false
        return message
    end

    def suspension_for_letter(incident_id)
        suspension = self.suspensions.where(incident_id: incident_id).first
        if suspension
            if suspension.letter.attached?
                return suspension.letter
            else
                return false
            end
        else
            return false
        end
    end

    def full_address
        address = ''
        address += self.address if self.address
        address += ' ' + self.city if self.city
        address += ' ' + self.state if self.state
        address += ' ' + self.zip.to_s if self.zip
        return address
    end

    def is_suspended
        today = Date.today
        suspension = self.suspensions
        suspension.each do |s|
            if s.until > today && s.incident.published == true
                return true
            end
        end
        return false
    end

    def suspension_expired
        yesterday = Date.yesterday.in_time_zone("Eastern Time (US & Canada)")
        latest_suspension = self.suspensions.joins(:incident).where(incident: { published: true }).order(until: :desc)[0]
        if !latest_suspension.nil? && latest_suspension.until == yesterday
            return true, latest_suspension
        else
            return false, latest_suspension
        end
    end

    def suspended_until
        suspension = self.suspensions.joins(:incident).where(incidents: { published: true }).order(until: :desc).first
        return suspension.until.strftime("%m/%d/%Y")
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
        return self.incidents.where(published: true).order(date_of: :desc).uniq
    end

    def violations_per_incident(incident_id)
        all_violations_for_incidents = self.violations.where(incident_id: incident_id).to_a
        if all_violations_for_incidents.size > 1
            violations = []
            all_violations_for_incidents.each do |v|
                violations.push(v) unless v.description == "None"
            end
        else
            violations = all_violations_for_incidents
        end
        return violations
    end

    def as_json(options={})
        options[:methods] = [:suspended_until]
        super
    end

end
