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
  throttle("reviews/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path.match?(%r{/products/.*/reviews}) && req.post?
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

  # Return 429 with a plain-text message when throttled
  self.throttled_responder = lambda do |request|
    [
      429,
      { "Content-Type" => "text/plain" },
      [ "Too many requests. Please wait a moment and try again." ]
    ]
  end
end
