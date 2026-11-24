class User < ApplicationRecord
  GOOGLE_PROVIDER = "google_oauth2"

  def self.from_omniauth(auth)
    domain = ENV["AUTH_DOMAIN"].to_s.strip.downcase
    return if domain.blank? || auth.nil?

    info = auth.fetch("info", {})
    hosted_domain = auth.dig("extra", "raw_info", "hd").to_s.downcase
    email = info["email"].to_s.strip.downcase
    uid = auth["uid"].to_s
    return unless auth["provider"] == GOOGLE_PROVIDER && uid.present?
    return unless hosted_domain == domain && info["email_verified"] == true && email.present?

    identity = { provider: GOOGLE_PROVIDER, uid: uid }
    user = find_by(identity) || create_or_find_by!(identity)
    user.update!(name: info["name"].presence || email, email: email)
    user
  end

  def can_suspend
    permitted_email?("CAN_SUSPEND")
  end

  def can_edit_incident(incident)
    incident.created_by.to_s == id.to_s || permitted_email?("CAN_EDIT")
  end

  def can_view_incident(incident)
    incident.published? || can_edit_incident(incident)
  end

  def is_super_admin
    permitted_email?("SUPER_ADMIN")
  end

  def my_comment(comment)
    comment.user_id == id
  end

  def can_delete_this_incident(incident)
    is_super_admin || (!incident.published? && incident.created_by.to_s == id.to_s)
  end

  private

  def permitted_email?(variable)
    address = email.to_s.strip.downcase
    address.present? && ENV[variable].to_s.split(",").any? { |entry| entry.strip.downcase == address }
  end
end
