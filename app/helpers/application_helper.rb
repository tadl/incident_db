module ApplicationHelper

    def am_i_checked(object_value, form_value)
        if object_value == form_value
            return 'checked=true'
        end
    end
    
end
