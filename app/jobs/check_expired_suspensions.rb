require 'sidekiq-scheduler'

class CheckExpiredSuspensions
  include Sidekiq::Worker
  def perform
    patrons = Patron.all
    patrons.each do |p|
        is_expired = p.suspension_expired
        if is_expired[0] == true && is_expired[1].expired_email_sent == false
            patron = p
            suspension = is_expired[1]
            IncidentMailer.suspension_expired(patron).deliver
            suspension.expired_email_sent = true
            suspension.save
        end
    end
  end
end