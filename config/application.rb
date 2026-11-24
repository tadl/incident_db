require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module IncidentDB
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])
    config.time_zone = "Eastern Time (US & Canada)"
    config.active_storage.draw_routes = false
    config.active_storage.variant_processor = :vips
    config.active_job.log_arguments = false

    config.session_store :cookie_store, key: "_incident_db_staff_session",
      same_site: :lax, expire_after: 12.hours
    config.action_dispatch.default_headers.merge!(
      "Referrer-Policy" => "strict-origin",
      "X-Robots-Tag" => "noindex, nofollow, noarchive"
    )
  end
end
