Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :none
    policy.base_uri :none
    policy.connect_src :self
    policy.font_src :self
    policy.form_action :self, "https://accounts.google.com"
    policy.frame_ancestors :none
    policy.img_src :self, :data
    policy.script_src :self
    policy.style_src :self, :unsafe_inline
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
