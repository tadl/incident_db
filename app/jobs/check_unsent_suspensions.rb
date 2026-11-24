class CheckUnsentSuspensions
  include Sidekiq::Job

  def perform
    return unless IncidentMailer.perform_deliveries

    Suspension.published.active.where(issued_email_sent: [false, nil]).find_each do |suspension|
      SuspensionPublishedJob.perform_now(suspension)
    end
  end
end
