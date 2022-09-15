class User < ApplicationRecord
    def self.from_omniauth(auth) 
        if auth.extra.raw_info.hd == ENV['AUTH_DOMAIN']
            user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
            user.provider = auth.provider
            user.uid = auth.uid
            user.name = auth.info.name
            user.email = auth.info.email
            user.avatar = auth.info.image
            user.oauth_token = auth.credentials.token
            user.oauth_expires_at = Time.at(auth.credentials.expires_at)
            user.save!
            return user
        else
            return false
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

    def is_super_admin
        if ENV['SUPER_ADMIN'].split(',').include? self.email
            return true
        else
            return false
        end
    end

    def my_comment(comment)
        if comment.user_id == self.id
            return true
        else
            return false
        end
    end

    def can_delete_this_incident(incident)
        if (incident.published != true && (incident.created_by == self.id.to_s)) || self.is_super_admin
            return true
        else
            return false
        end
    end
end