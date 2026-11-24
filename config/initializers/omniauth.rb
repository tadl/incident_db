OmniAuth.config.allowed_request_methods = [:post]
# Provider exceptions can include credential responses. Rails logs the generic
# failure endpoint once the middleware has discarded the provider's details.
OmniAuth.config.logger = Logger.new(IO::NULL)
OmniAuth.config.on_failure = ->(_env) do
  [302, { "location" => "/auth/failure", "cache-control" => "no-store" }, []]
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"],
    access_type: "online", hd: ENV["AUTH_DOMAIN"], scope: "openid,email,profile",
    overridable_authorize_options: [], origin_param: false
end
