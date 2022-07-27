class Rule < ApplicationRecord
    validates :track, presence: { message: 'Please select a track' }
    validates :track, acceptance: {accept: ['A', 'B'], message: "Invalid track"}
    validates :description, presence: { message: 'Description required' }, allow_blank: false
    validates :description, uniqueness: { message: 'An infraction type with this description already exisits'}
end