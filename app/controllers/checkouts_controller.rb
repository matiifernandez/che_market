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
        coupon_id: @cart.coupon_id
      }
    }

    # Apply discount if coupon is present
    if @cart.coupon.present? && @cart.discount_cents > 0
      stripe_coupon = create_stripe_coupon(@cart)
      session_params[:discounts] = [{ coupon: stripe_coupon.id }]
    end

    session = Stripe::Checkout::Session.create(session_params)

    redirect_to session.url, allow_other_host: true
  end

  def success
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
    coupon_id = stripe_session.metadata&.coupon_id
    coupon = Coupon.find_by(id: coupon_id) if coupon_id.present?
    discount_cents = stripe_session.total_details&.amount_discount || 0

    order = Order.create!(
      user: current_user,
      cart: current_cart,
      status: :paid,
      total_cents: stripe_session.amount_total,
      discount_cents: discount_cents,
      coupon: coupon,
      stripe_session_id: stripe_session.id,
      email: stripe_session.customer_details.email
    )

    # Increment coupon usage if present
    coupon&.increment_usage!

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

    # Clear coupon from cart
    current_cart.remove_coupon

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

  def create_stripe_coupon(cart)
    coupon = cart.coupon

    coupon_params = {
      id: "#{coupon.code}_#{Time.current.to_i}",
      name: "#{coupon.code} - #{coupon.formatted_discount}",
      duration: "once"
    }

    if coupon.percentage?
      coupon_params[:percent_off] = coupon.discount_percentage
    else
      coupon_params[:amount_off] = cart.discount_cents
      coupon_params[:currency] = "usd"
    end

    Stripe::Coupon.create(coupon_params)
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
