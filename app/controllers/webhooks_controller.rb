class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError
      render json: { error: "Invalid payload" }, status: 400
      return
    rescue Stripe::SignatureVerificationError
      render json: { error: "Invalid signature" }, status: 400
      return
    end

    case event.type
    when "checkout.session.completed"
      session_data = event.data.object

      if session_data.metadata&.type == "gift_card"
        handle_gift_card_purchase(session_data)
      else
        handle_checkout_completed(session_data)
      end
    end

    render json: { received: true }, status: 200
  end

  private

  def handle_checkout_completed(session)
    return if Order.exists?(stripe_session_id: session.id)

    # Buscar el carrito por email o session
    cart = find_cart_for_session(session)

    # Get coupon from metadata if present
    coupon_id = session.metadata&.coupon_id
    coupon = Coupon.find_by(id: coupon_id) if coupon_id.present?
    discount_cents = session.total_details&.amount_discount || 0

    order = Order.create!(
      status: :paid,
      total_cents: session.amount_total,
      discount_cents: discount_cents,
      coupon: coupon,
      stripe_session_id: session.id,
      email: session.customer_details.email,
      cart: cart
    )

    # Increment coupon usage if present
    coupon&.increment_usage!

    if cart
      cart.cart_items.includes(:product).each do |cart_item|
        order.line_items.create!(
          product: cart_item.product,
          quantity: cart_item.quantity,
          price_cents: cart_item.product.price_cents
        )
        # Decrement product stock
        cart_item.product.decrement!(:stock, cart_item.quantity)
      end

      # Clear coupon from cart
      cart.remove_coupon
    end

    # Send emails
    OrderMailer.confirmation(order).deliver_now
    OrderMailer.admin_notification(order).deliver_now
  end

  def find_cart_for_session(session)
    # Primero intentar encontrar el carrito por email
    if session.customer_details&.email
      user = User.find_by(email: session.customer_details.email)
      return user.cart if user&.cart
    end

    # Si no se encuentra por email, buscar por carritos recientes con items.
    Cart.joins(:cart_items).order(updated_at: :desc).first
  end

  def handle_gift_card_purchase(session)
    gift_card = GiftCard.find_by(id: session.metadata&.gift_card_id)
    return unless gift_card
    return if gift_card.active? # Ya procesada

    # Activar la gift card
    gift_card.activate!

    # Enviar email al destinatario
    GiftCardMailer.delivery(gift_card).deliver_now
    gift_card.mark_as_delivered!

    # Notificar al admin
    GiftCardMailer.admin_notification(gift_card).deliver_now
  end
end
