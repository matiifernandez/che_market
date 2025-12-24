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

      if session_data.metadata['type'] == "gift_card"
        handle_gift_card_purchase(session_data)
      else
        handle_checkout_completed(session_data)
      end
    end

    render json: { received: true }, status: 200
  end

  private

  def handle_checkout_completed(session)
    # Use transaction to ensure atomicity
    ActiveRecord::Base.transaction do
      # Check if order already exists (created by success callback)
      return if Order.exists?(stripe_session_id: session.id)

      # Find cart using cart_id from metadata (reliable) or fallback methods
      cart = find_cart_for_session(session)

      # Get coupon and gift card from metadata
      coupon_id = session.metadata['coupon_id']
      coupon = Coupon.find_by(id: coupon_id) if coupon_id.present?

      gift_card_id = session.metadata['gift_card_id']
      gift_card_amount = session.metadata['gift_card_amount_cents'].to_i
      gift_card = GiftCard.find_by(id: gift_card_id) if gift_card_id.present?

      # Calculate coupon discount (total discount minus gift card amount)
      total_stripe_discount = session.total_details&.amount_discount || 0
      coupon_discount = [ total_stripe_discount - gift_card_amount, 0 ].max

      order = Order.create!(
        status: :paid,
        total_cents: session.amount_total,
        discount_cents: coupon_discount,
        coupon: coupon,
        gift_card: gift_card,
        gift_card_amount_cents: gift_card_amount,
        stripe_session_id: session.id,
        email: session.customer_details.email,
        cart: cart
      )

      # Increment coupon usage
      coupon&.increment_usage!

      # Apply gift card if present
      if gift_card && gift_card_amount > 0
        gift_card.apply_to_order(order, gift_card_amount)
      end

      if cart
        cart.cart_items.includes(:product).each do |cart_item|
          order.line_items.create!(
            product: cart_item.product,
            quantity: cart_item.quantity,
            price_cents: cart_item.product.price_cents
          )
          cart_item.product.decrement!(:stock, cart_item.quantity)
        end

        cart.remove_coupon
        cart.remove_gift_card
      end

      # Send emails
      OrderMailer.confirmation(order).deliver_now
      OrderMailer.admin_notification(order).deliver_now
    end
  rescue ActiveRecord::RecordNotUnique
    # Order was created by success callback while we were processing - that's fine
    Rails.logger.info("Order already exists for session #{session.id} - likely created by success callback")
  end

  def find_cart_for_session(session)
    # First try to find cart by ID from metadata (most reliable)
    cart_id = session.metadata['cart_id']
    cart = Cart.find_by(id: cart_id) if cart_id.present?
    return cart if cart

    # Fallback: find by user email
    if session.customer_details&.email
      user = User.find_by(email: session.customer_details.email)
      return user.cart if user&.cart
    end

    # Last resort: most recently updated cart with items (not ideal but prevents order without items)
    Rails.logger.warn("Could not find cart by ID or email for session #{session.id}, using fallback")
    Cart.joins(:cart_items).order(updated_at: :desc).first
  end

  def handle_gift_card_purchase(session)
    gift_card = GiftCard.find_by(id: session.metadata['gift_card_id'])
    return unless gift_card

    # Use database-level locking to prevent race condition with success callback
    gift_card.with_lock do
      return unless gift_card.pending?

      gift_card.activate!
      GiftCardMailer.delivery(gift_card).deliver_now
      gift_card.mark_as_delivered!
      GiftCardMailer.admin_notification(gift_card).deliver_now
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("Gift card #{session.metadata['gift_card_id']} not found")
  end
end
