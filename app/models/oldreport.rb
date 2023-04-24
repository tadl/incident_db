class Oldreport < ApplicationRecord
    include PgSearch::Model
    
    has_many_attached :images do |attachable|
        attachable.variant :thumb, resize_to_fill: [250, 250]
    end

    pg_search_scope :search, against: [:title, :description, :narrative, :legacy_id, :patron_name, :submitted_by],using: {
        tsearch: {prefix: true}
    }

    def time_of_in_zone 
        return self.time_of.strftime("at %l:%M %p") rescue ''
    end

    def date_of_pretty
        return self.date_of.strftime("%m/%d/%Y")
    end

    def primary_pic
        if self.images.size >= 1
            return self.images[0]
        end
    end

    def violations
        violations = self.a_violations + self.b_violations
        #detects if string contains a capital A or B followed by a number
        regex = /([AB]\d+)/
        i = 0
        violations.gsub!(regex) do |match|
            ", #{match}"
        end
        return violations.sub!(/\A\s*,\s*/, '')
    end

    def has_violations?
        if self.a_violations == '' && self.b_violations == ''
            return false
        else
            return true
        end
    end

end
