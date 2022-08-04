class Patron < ApplicationRecord

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
end
