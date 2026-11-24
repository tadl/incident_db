class IncidentMailer < ApplicationMailer
  def incident_published(incident)
    incident_notice(incident, "New incident report")
  end

  def suspension_published(incident)
    incident_notice(incident, "New suspension")
  end

  def suspension_expired(patron)
    record_notice(ENV["EMAIL_TO"], "Suspension expired", patrons_view_url(id: patron.id), "Open patron record")
  end

  def comment_added(parent)
    if parent.is_a?(Incident)
      incident_notice(parent, "New incident comment", ENV["COMMENT_EMAIL_TO"])
    else
      record_notice(ENV["COMMENT_EMAIL_TO"], "New patron comment", patrons_view_url(id: parent.id), "Open patron record")
    end
  end

  private

  def incident_notice(incident, subject, recipient = ENV["EMAIL_TO"])
    record_notice(recipient, subject, incidents_view_url(id: incident.id), "Open incident report")
  end

  def record_notice(recipient, subject, url, link_text)
    @record_url = url
    @link_text = link_text
    mail(to: recipient, subject: subject, template_name: "record_notice")
  end
end
