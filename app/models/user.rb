class User < ApplicationRecord
    def self.from_omniauth(auth)
        where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
            if auth.extra.raw_info.hd == ENV['AUTH_DOMAIN']
                user.provider = auth.provider
                user.uid = auth.uid
                user.name = auth.info.name
                user.email = auth.info.email
                user.avatar = auth.info.image
                user.oauth_token = auth.credentials.token
                user.oauth_expires_at = Time.at(auth.credentials.expires_at)
                user.save!
            else
                return false
            end
        end
    end

    def can_suspend
        if ENV['CAN_SUSPEND'].split(',').include? self.email
            return true
        else
            return false
        end
    end

    def can_edit_incident(incident_id)
        incident = Incident.find(incident_id)
        if incident.created_by == self.id.to_s || (ENV['CAN_EDIT'].split(',').include? self.email) 
            return true
        else
            return false
        end   
    end

    def my_comment

    end


end