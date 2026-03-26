class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    if endpoint_secret.blank?
      Rails.logger.error("[Webhook] STRIPE_WEBHOOK_SECRET missing")
      render json: { error: "Webhook misconfigured" }, status: 500
      return
    end

    if sig_header.blank?
      render json: { error: "Missing signature" }, status: 400
      return
    end

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError
      render json: { error: "Invalid payload" }, status: 400
      return
    rescue Stripe::SignatureVerificationError
      render json: { error: "Invalid signature" }, status: 400
      return
    end

    webhook_event = nil
    begin
      webhook_event = StripeWebhookEvent.create!(
        stripe_event_id: event.id,
        event_type: event.type,
        livemode: event.livemode,
        payload: event.to_hash,
        status: "received"
      )
    rescue ActiveRecord::RecordNotUnique
      render json: { received: true }, status: 200
      return
    end

    begin
      case event.type
      when "checkout.session.completed"
        session_data = event.data.object

        if session_data.metadata['type'] == "gift_card"
          handle_gift_card_purchase(session_data)
        else
          handle_checkout_completed(session_data)
        end

        webhook_event.update!(status: "processed", processed_at: Time.current)
      else
        webhook_event.update!(status: "ignored", processed_at: Time.current)
      end
    rescue StandardError => e
      webhook_event&.update!(status: "failed", processed_at: Time.current, error_message: e.message)
      raise
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
      OrderCreationService.new(
        cart: cart,
        stripe_session: session,
        email: session.customer_details&.email,
        log_prefix: "[Webhook]"
      ).create_from_stripe!
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

    Rails.logger.error("[Webhook] Could not find cart for session #{session.id}. Proceeding without line items.")
    nil
  end

  def handle_gift_card_purchase(session)
    gift_card = GiftCard.find_by(id: session.metadata['gift_card_id'])
    return unless gift_card

    # Use database-level locking to prevent race condition with success callback
    gift_card.with_lock do
      return unless gift_card.pending?

      gift_card.activate!
      GiftCardMailer.delivery(gift_card).deliver_later
      gift_card.mark_as_delivered!
      GiftCardMailer.admin_notification(gift_card).deliver_later
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("Gift card #{session.metadata['gift_card_id']} not found")
  end
end
