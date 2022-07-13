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
end