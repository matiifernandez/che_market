class CheckoutsController < ApplicationController
  def create
    @cart = current_cart

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

    # Calculate amounts
    gift_card_amount = @cart.gift_card_amount_to_apply
    amount_to_charge = @cart.total_cents

    # If gift card covers the entire purchase, process without Stripe
    if amount_to_charge.zero? && gift_card_amount > 0
      order = create_order_paid_with_gift_card
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
      success_url: success_checkout_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: cancel_checkout_url,
      metadata: {
        cart_id: @cart.id,
        coupon_id: @cart.coupon_id,
        gift_card_id: @cart.gift_card_id,
        gift_card_amount_cents: gift_card_amount
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

    if params[:session_id]
      @order = Order.find_by(stripe_session_id: params[:session_id])

      # Si el webhook aún no procesó, esperamos un poco
      if @order.nil?
        sleep(2)
        @order = Order.find_by(stripe_session_id: params[:session_id])
      end

      # Si aún no existe la orden, la creamos aca (backup)
      if @order.nil?
        @session = Stripe::Checkout::Session.retrieve(params[:session_id])
        @order = create_order_from_session(@session)
      end

      # Limpiar el carrito si hay orden
      if @order
        current_cart.cart_items.destroy_all
        session.delete(:cart_secret_id)
      end
    end
  end

  def cancel
  end

  private

  def create_order_from_session(stripe_session)
    # Get coupon from metadata if present
    coupon_id = stripe_session.metadata['coupon_id']
    coupon = Coupon.find_by(id: coupon_id) if coupon_id.present?

    # Get gift card from metadata if present
    gift_card_id = stripe_session.metadata['gift_card_id']
    gift_card_amount = stripe_session.metadata['gift_card_amount_cents'].to_i
    gift_card = GiftCard.find_by(id: gift_card_id) if gift_card_id.present?

    # Calculate discount (coupon only, gift card is separate)
    total_stripe_discount = stripe_session.total_details&.amount_discount || 0
    coupon_discount = total_stripe_discount - gift_card_amount
    coupon_discount = [coupon_discount, 0].max

    order = Order.create!(
      user: current_user,
      cart: current_cart,
      status: :paid,
      total_cents: stripe_session.amount_total,
      discount_cents: coupon_discount,
      coupon: coupon,
      gift_card: gift_card,
      gift_card_amount_cents: gift_card_amount,
      stripe_session_id: stripe_session.id,
      email: stripe_session.customer_details.email
    )

    # Increment coupon usage if present
    coupon&.increment_usage!

    # Apply gift card if present
    if gift_card && gift_card_amount > 0
      gift_card.apply_to_order(order, gift_card_amount)
    end

    # Save line items and decrement stock
    current_cart.cart_items.includes(:product).each do |cart_item|
      order.line_items.create!(
        product: cart_item.product,
        quantity: cart_item.quantity,
        price_cents: cart_item.product.price_cents
      )
      # Decrement product stock
      cart_item.product.decrement!(:stock, cart_item.quantity)
    end

    # Clear coupon and gift card from cart
    current_cart.remove_coupon
    current_cart.remove_gift_card

    # Send emails
    OrderMailer.confirmation(order).deliver_now
    OrderMailer.admin_notification(order).deliver_now

    order
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

  def create_order_paid_with_gift_card
    gift_card = current_cart.gift_card
    return nil unless gift_card&.valid_for_use?

    gift_card_amount = current_cart.gift_card_amount_to_apply
    email = current_user&.email || "guest@chemarket.com"

    order = Order.create!(
      user: current_user,
      cart: current_cart,
      status: :paid,
      total_cents: 0,
      discount_cents: current_cart.discount_cents,
      coupon: current_cart.coupon,
      gift_card: gift_card,
      gift_card_amount_cents: gift_card_amount,
      email: email
    )

    # Create line items and decrement stock
    current_cart.cart_items.includes(:product).each do |cart_item|
      order.line_items.create!(
        product: cart_item.product,
        quantity: cart_item.quantity,
        price_cents: cart_item.product.price_cents
      )
      cart_item.product.decrement!(:stock, cart_item.quantity)
    end

    # Apply gift card balance
    gift_card.apply_to_order(order, gift_card_amount)

    # Increment coupon usage if present
    current_cart.coupon&.increment_usage!

    # Clear cart
    current_cart.remove_coupon
    current_cart.remove_gift_card
    current_cart.cart_items.destroy_all

    # Send emails
    OrderMailer.confirmation(order).deliver_later
    OrderMailer.admin_notification(order).deliver_later

    order
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
