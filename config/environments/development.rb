Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  config.action_controller.perform_caching = false
  config.cache_store = :null_store
  config.active_storage.service = :local

  config.action_mailer.perform_deliveries = false
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.assets.quiet = true
  config.action_controller.raise_on_missing_callback_actions = true
  config.hosts.concat([ENV["DEV_HOSTNAME"]].compact_blank)
end
