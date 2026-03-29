class Rack::Attack
  # Explicitly set cache store so throttles work correctly across multiple app instances.
  # In production, Rails.cache should be backed by a shared store (Redis/Memcached).
  Rack::Attack.cache.store = Rails.cache

  ### Throttle Sensitive Endpoints ###

  # Throttle login attempts: 10 per 20 seconds per IP
  throttle("login/ip", limit: 10, period: 20.seconds) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # Throttle account creation (Sign up): 5 per hour per IP to prevent bot accounts
  throttle("registrations/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/users" && req.post?
  end

  # Throttle password reset requests: 5 per hour per IP
  throttle("password_reset/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/users/password" && req.post?
  end

  # Throttle checkout/order creation: 10 per minute per IP to prevent card testing/fraud
  throttle("checkout/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/checkout" && req.post?
  end

  # Throttle product search: 30 per minute per IP to prevent heavy scraping
  throttle("search/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path == "/products" && req.params["q"].present?
  end

  # Throttle review creation: 5 per hour per IP to prevent spam
  # Tightened regex to only match the index/create route, not nested actions like 'helpful'
  throttle("reviews/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path.match?(%r{\A/products/[^/]+/reviews\z}) && req.post?
  end

  # Throttle Admin write actions: 20 per minute per IP
  # Protects against automated changes or brute force in the admin panel
  throttle("admin/write", limit: 20, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/admin") && %w[POST PATCH PUT DELETE].include?(req.request_method)
  end

  # Throttle coupon code redemption: 10 per minute per IP
  throttle("coupon/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/cart/coupon" && req.post?
  end

  # Throttle gift card application: 10 per minute per IP
  throttle("gift_card_apply/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/cart/gift_card" && req.post?
  end

  # Throttle gift card balance checks: 20 per minute per IP
  throttle("gift_card_balance/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.path == "/gift_cards/balance" && req.post?
  end

  # Throttle CSP report ingestion: 60 per minute per IP
  throttle("csp_reports/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path == "/csp_reports" && req.post?
  end

  # Customized responder with Localization and HTML support
  self.throttled_responder = lambda do |request|
    # Detect locale from params or default
    locale = request.params["locale"] || I18n.default_locale
    message = I18n.t("errors.messages.throttled", locale: locale, default: "Too many requests. Please wait a moment and try again.")
    
    if request.env["action_dispatch.request.accepts"]&.any? { |m| m.html? }
      [
        429,
        { "Content-Type" => "text/html" },
        [
          "<html><head><meta charset='UTF-8'><title>#{message}</title></head>" \
          "<body style='font-family:sans-serif; display:flex; justify-content:center; align-items:center; height:100vh; margin:0; background:#f9fafb;'>" \
          "<div style='background:white; padding:2rem; border-radius:0.5rem; shadow:0 1px 3px rgba(0,0,0,0.1); text-align:center; max-width:400px;'>" \
          "<h1 style='color:#111827; font-size:1.25rem; margin-bottom:1rem;'>#{message}</h1>" \
          "<p style='color:#6b7280;'>#{I18n.t('errors.messages.throttled_desc', locale: locale, default: 'Please try again in a few minutes.')}</p>" \
          "</div></body></html>"
        ]
      ]
    else
      [
        429,
        { "Content-Type" => "text/plain" },
        [ message ]
      ]
    end
  end
end
