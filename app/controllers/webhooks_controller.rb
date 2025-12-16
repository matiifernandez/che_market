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
      handle_checkout_completed(event.data.object)
    end

    render json: { received: true }, status: 200
  end

  private

  def handle_checkout_completed(session)
    return if Order.exists?(stripe_session_id: session.id)

    # Buscar el carrito por email o session
    cart = find_cart_for_session(session)

    order = Order.create!(
      status: :paid,
      total_cents: session.amount_total,
      stripe_session_id: session.id,
      email: session.customer_details.email,
      cart: cart
    )

    if cart
      cart.cart_items.includes(:product).each do |cart_item|
        order.line_items.create!(
          product: cart_item.product,
          quantity: cart_item.quantity,
          price_cents: cart_item.product.price_cents
        )
      end
    end
    # Envia los emails.

    OrderMailer.confirmation(order).deliver_now
    OrderMailer.admin_notification(order).deliver_now
  end

  def find_cart_for_session(session)
    # Primero intentar encontrar el carrito por email
    if session.customer_details&.email
      user = User.find_by(email: session.customer_details.email)
      return user.cart if user&.cart
    end

    #Si no se encuentra por email, buscar por carritos recientes con items.
    Cart.joins(:cart_items).order(updated_at: :desc).first
  end
end
