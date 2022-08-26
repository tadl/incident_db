require 'sidekiq-scheduler'

class CheckUnsentSuspensions
  include Sidekiq::Worker
  def perform
    suspensions = Suspension.where(issued_email_sent: false)
    suspensions.each do |s|
        if s.incident.published == true
            patron = s.patron
            incident = s.incident
            IncidentMailer.suspension_published(patron, incident, s).deliver
            s.issued_email_sent = true
            s.save
        end
    end
  end
end