Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https, "https://js.stripe.com"
    policy.style_src   :self, :https, :unsafe_inline
    policy.frame_src   "https://js.stripe.com", "https://hooks.stripe.com"
    policy.connect_src :self, :https
    policy.base_uri    :self
    policy.form_action :self
  end

  # Nonce support for importmap inline scripts
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]
end
