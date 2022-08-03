module IncidentsHelper
    def incident_time_helper(incident, date_time_today)
        if incident.date_of
            return incident.date_of.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y,  %H:%M")
        else
            date_time_today
        end
    end
end
