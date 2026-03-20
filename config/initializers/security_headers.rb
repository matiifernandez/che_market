# Be sure to restart your server when you modify this file.

# Configure baseline security headers (HSTS, XFO, XCTO, Referrer-Policy).
# Note: HSTS is enabled via config.force_ssl = true in production.rb
# Note: Content Security Policy is managed in content_security_policy.rb

Rails.application.config.action_dispatch.default_headers.merge!(
  "X-Frame-Options" => "DENY",
  "X-Content-Type-Options" => "nosniff",
  "X-XSS-Protection" => "0",
  "Referrer-Policy" => "strict-origin-when-cross-origin"
)
