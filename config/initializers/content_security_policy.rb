Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, "https://js.stripe.com"
    policy.style_src   :self, :https, :unsafe_inline
    policy.frame_src   "https://js.stripe.com", "https://hooks.stripe.com"
    policy.connect_src :self, :https
    policy.base_uri    :self
    policy.form_action :self
  end

  # Generate a fresh random nonce per request (session.id is stable and weakens CSP protection)
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
