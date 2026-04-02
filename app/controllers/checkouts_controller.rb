class CheckoutsController < ApplicationController
  def create
    @cart = current_cart

    # Idempotency: redirect to existing paid order on retry (handles case where cart is already cleared)
    existing_order = Order.find_by(cart: @cart, status: :paid)
    if existing_order
      redirect_to success_checkout_path(order_id: existing_order.id)
      return
    end

    if @cart.cart_items.empty?
      redirect_to cart_path, alert: "Tu carrito está vacío"
      return
    end

    # Validate stock availability before proceeding to payment
    @cart.cart_items.includes(:product).each do |item|
      if item.quantity > item.product.stock
        redirect_to cart_path, alert: "No hay suficiente stock de #{item.product.name}. Disponible: #{item.product.stock}"
        return
      end
    end

    risk = evaluate_checkout_risk
    if risk.blocked?
      redirect_to cart_path, alert: t("checkout.velocity_blocked")
      return
    end

    # Calculate amounts
    gift_card_amount = @cart.gift_card_amount_to_apply
    amount_to_charge = @cart.total_cents

    # If gift card covers the entire purchase, process without Stripe
    if amount_to_charge.zero? && gift_card_amount > 0
      order = create_order_paid_with_gift_card(risk)
      if order
        redirect_to success_checkout_path(order_id: order.id)
        return
      else
        redirect_to cart_path, alert: t("checkout.error")
        return
      end
    end

    session_params = {
      mode: "payment",
      customer_email: current_user&.email,
      line_items: build_line_items(@cart),
      shipping_address_collection: {
        allowed_countries: shipping_countries
      },
      success_url: "#{success_checkout_url}#{success_checkout_url.include?('?') ? '&' : '?'}session_id={CHECKOUT_SESSION_ID}",
      cancel_url: cancel_checkout_url,
      metadata: {
        cart_id: @cart.id,
        coupon_id: @cart.coupon_id,
        gift_card_id: @cart.gift_card_id,
        gift_card_amount_cents: gift_card_amount,
        risk_flags: risk.flags.join(","),
        risk_score: risk.score.to_s,
        risk_level: risk.level.to_s,
        checkout_ip: request.remote_ip.to_s,
        checkout_user_agent: truncate_user_agent(request.user_agent)
      }
    }

    # Apply combined discount (coupon + gift card) if present
    total_discount = @cart.discount_cents + gift_card_amount
    if total_discount > 0
      stripe_coupon = create_combined_stripe_discount(@cart, total_discount)
      session_params[:discounts] = [{ coupon: stripe_coupon.id }]
    end

    session = Stripe::Checkout::Session.create(session_params)

    redirect_to session.url, allow_other_host: true
  end

  def success
    # Check if this was a gift card only purchase (no Stripe)
    if params[:order_id]
      @order = Order.find_by(id: params[:order_id])
      return
    end

    return unless params[:session_id]

    # Try to find existing order (may have been created by webhook)
    @order = Order.find_by(stripe_session_id: params[:session_id])

    # If order doesn't exist, create it now
    # The unique index on stripe_session_id prevents duplicates
    if @order.nil?
      @order = safely_create_order_from_stripe(params[:session_id])
    end

    # Clear cart if order exists
    if @order
      current_cart.cart_items.destroy_all
      session.delete(:cart_secret_id)
    end
  end

  def cancel
  end

  private

  def safely_create_order_from_stripe(session_id)
    stripe_session = Stripe::Checkout::Session.retrieve(session_id)

    # Use a transaction to ensure atomicity
    ActiveRecord::Base.transaction do
      # Double-check order doesn't exist (in case webhook just created it)
      existing_order = Order.find_by(stripe_session_id: session_id)
      return existing_order if existing_order

      create_order_from_session(stripe_session)
    end
  rescue ActiveRecord::RecordNotUnique
    # Race condition: webhook created the order while we were processing
    # Just find and return the order created by webhook
    Order.find_by(stripe_session_id: session_id)
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe error retrieving session #{session_id}: #{e.message}")
    nil
  end

  def create_order_from_session(stripe_session)
    OrderCreationService.new(
      cart: current_cart,
      user: current_user,
      stripe_session: stripe_session,
      log_prefix: "[Checkout]"
    ).create_from_stripe!
  end

  def build_line_items(cart)
    cart.cart_items.includes(:product).map do |item|
      {
        price_data: {
          currency: "usd",
          unit_amount: item.product.price_cents,
          product_data: {
            name: item.product.name,
            description: item.product.category&.name
          }
        },
        quantity: item.quantity
      }
    end
  end

  def create_combined_stripe_discount(cart, total_discount_cents)
    coupon_code = cart.coupon&.code || "CREDIT"

    Stripe::Coupon.create(
      id: "#{coupon_code}_#{Time.current.to_i}",
      name: "Descuento aplicado",
      duration: "once",
      amount_off: total_discount_cents,
      currency: "usd"
    )
  end

  def create_order_paid_with_gift_card(risk)
    gift_card = current_cart.gift_card
    return nil unless gift_card&.valid_for_use?

    ActiveRecord::Base.transaction do
      # Lock the cart row to prevent concurrent submissions creating duplicate orders
      current_cart.with_lock do
        # Re-check idempotency after acquiring lock
        existing_order = Order.find_by(cart: current_cart, status: :paid)
        return existing_order if existing_order
        OrderCreationService.new(
          cart: current_cart,
          user: current_user,
          log_prefix: "[Checkout]"
        ).create_from_gift_card!(
          risk: risk,
          checkout_ip: request.remote_ip.to_s,
          checkout_user_agent: truncate_user_agent(request.user_agent)
        )
      end
    end
  end

  def evaluate_checkout_risk
    email = current_user&.email
    email ||= params[:email] if params[:email].present?

    CheckoutRiskEvaluator.new(
      user: current_user,
      email: email,
      ip: request.remote_ip
    ).evaluate
  end

  def truncate_user_agent(user_agent)
    user_agent.to_s.first(255)
  end

  def shipping_countries
  %w[
      AC AD AE AF AG AI AL AM AO AQ AR AT AU AW AX AZ
      BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ
      CA CD CF CG CH CI CK CL CM CN CO CR CV CW CY CZ
      DE DJ DK DM DO DZ EC EE EG EH ER ES ET
      FI FJ FK FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY
      HK HN HR HT HU ID IE IL IM IN IO IQ IS IT
      JE JM JO JP KE KG KH KI KM KN KR KW KY KZ
      LA LB LC LI LK LR LS LT LU LV LY
      MA MC MD ME MF MG MK ML MM MN MO MQ MR MS MT MU MV MW MX MY MZ
      NA NC NE NG NI NL NO NP NR NU NZ OM
      PA PE PF PG PH PK PL PM PN PR PS PT PY QA
      RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SV SX SZ
      TA TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ
      UA UG US UY UZ VA VC VE VG VN VU WF WS XK YE YT ZA ZM ZW ZZ
    ]
  end
end
