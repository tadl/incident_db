Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.assets.compile = false
  config.active_storage.service = :local

  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }
  config.hosts = [ENV["APP_HOST"].presence || "localhost", ENV["APP_ALIAS_HOST"].presence].compact
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new($stdout))
  config.log_tags = [:request_id]
  config.log_level = :info
  config.active_job.queue_adapter = :sidekiq
  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = ENV.fetch("MAIL_DELIVERY_ENABLED", "true") == "true"
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: ENV["APP_HOST"], protocol: "https" }
  config.action_mailer.smtp_settings = {
    address: "smtp.gmail.com",
    port: 587,
    domain: "tadl.org",
    user_name: ENV.fetch("SMTP_USERNAME", "tadlbot@tadl.org"),
    password: ENV["EMAIL_PASSWORD"],
    authentication: :plain,
    enable_starttls: true
  }
end
