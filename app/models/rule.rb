class Rule < ApplicationRecord
    validates :track, presence: { message: 'Please select a track' }
    validates :track, acceptance: {accept: ['A', 'B', 'None'], message: "Invalid track"}
    validates :description, presence: { message: 'Description required' }, allow_blank: false
    
    def violation_format
        violation_format = self.track + self.description
    end

end