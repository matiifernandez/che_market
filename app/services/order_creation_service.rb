# frozen_string_literal: true

class OrderCreationService
  def initialize(cart:, user: nil, stripe_session: nil, email: nil, log_prefix: "[Order]")
    @cart = cart
    @user = user
    @stripe_session = stripe_session
    @email = email
    @log_prefix = log_prefix
  end

  def create_from_stripe!
    raise ArgumentError, "stripe_session is required" unless @stripe_session

    metadata = @stripe_session.metadata || {}
    coupon_id = metadata["coupon_id"]
    coupon = Coupon.find_by(id: coupon_id) if coupon_id.present?

    gift_card_id = metadata["gift_card_id"]
    gift_card_amount = metadata["gift_card_amount_cents"].to_i
    gift_card = GiftCard.find_by(id: gift_card_id) if gift_card_id.present?

    total_stripe_discount = @stripe_session.total_details&.amount_discount || 0
    coupon_discount = [total_stripe_discount - gift_card_amount, 0].max

    email = @stripe_session.customer_details&.email || @user&.email || @email
    risk_flags = metadata["risk_flags"].to_s.split(",").reject(&:blank?)
    risk_score = metadata["risk_score"].to_i
    risk_level = metadata["risk_level"].presence
    checkout_ip = metadata["checkout_ip"].presence
    checkout_user_agent = metadata["checkout_user_agent"].presence

    create_order!(
      status: :paid,
      total_cents: @stripe_session.amount_total,
      discount_cents: coupon_discount,
      coupon: coupon,
      gift_card: gift_card,
      gift_card_amount_cents: gift_card_amount,
      stripe_session_id: @stripe_session.id,
      email: email,
      strict_stock: false,
      clear_cart_items: false,
      apply_gift_card_with_lock: false,
      risk_flags: risk_flags,
      risk_score: risk_score,
      risk_level: risk_level,
      checkout_ip: checkout_ip,
      checkout_user_agent: checkout_user_agent
    )
  end

  def create_from_gift_card!(risk: nil, checkout_ip: nil, checkout_user_agent: nil)
    gift_card = @cart&.gift_card
    return nil unless gift_card&.valid_for_use?

    gift_card_amount = @cart.gift_card_amount_to_apply
    email = @user&.email || @email || "guest@chemarket.com"
    risk_flags = risk&.flags || []
    risk_score = risk&.score || 0
    risk_level = risk&.level

    create_order!(
      status: :paid,
      total_cents: 0,
      discount_cents: @cart.discount_cents,
      coupon: @cart.coupon,
      gift_card: gift_card,
      gift_card_amount_cents: gift_card_amount,
      email: email,
      strict_stock: true,
      clear_cart_items: true,
      apply_gift_card_with_lock: true,
      risk_flags: risk_flags,
      risk_score: risk_score,
      risk_level: risk_level,
      checkout_ip: checkout_ip,
      checkout_user_agent: checkout_user_agent
    )
  end

  private

  def create_order!(status:, total_cents:, discount_cents:, coupon:, gift_card:, gift_card_amount_cents:,
                    stripe_session_id: nil, email:, strict_stock:, clear_cart_items:, apply_gift_card_with_lock:,
                    risk_flags:, risk_score:, risk_level:, checkout_ip:, checkout_user_agent:)
    Order.transaction do
      order = Order.create!(
        user: @user,
        cart: @cart,
        status: status,
        total_cents: total_cents,
        discount_cents: discount_cents,
        coupon: coupon,
        gift_card: gift_card,
        gift_card_amount_cents: gift_card_amount_cents,
        stripe_session_id: stripe_session_id,
        email: email,
        risk_flags: risk_flags || [],
        risk_score: risk_score || 0,
        risk_level: risk_level,
        checkout_ip: checkout_ip,
        checkout_user_agent: checkout_user_agent
      )

      coupon&.increment_usage!

      if gift_card && gift_card_amount_cents.to_i > 0
        apply_gift_card(order, gift_card, gift_card_amount_cents, apply_gift_card_with_lock)
      end

      if @cart
        @cart.cart_items.includes(:product).each do |cart_item|
          order.line_items.create!(
            product: cart_item.product,
            quantity: cart_item.quantity,
            price_cents: cart_item.product.price_cents
          )
          rows_updated = Product.where(id: cart_item.product_id)
                                .where("stock >= ?", cart_item.quantity)
                                .update_all(["stock = stock - ?", cart_item.quantity])
          if rows_updated == 0
            if strict_stock
              raise ActiveRecord::Rollback, "Insufficient stock for #{cart_item.product.name}"
            else
              Rails.logger.error(
                "#{@log_prefix} Insufficient stock for product #{cart_item.product_id} " \
                "(#{cart_item.product.name}) on order #{order.id}. Manual stock correction required."
              )
            end
          end
        end

        @cart.remove_coupon
        @cart.remove_gift_card
        @cart.cart_items.destroy_all if clear_cart_items
      end

      OrderMailer.confirmation(order).deliver_later
      OrderMailer.admin_notification(order).deliver_later

      order
    end
  end

  def apply_gift_card(order, gift_card, gift_card_amount_cents, lock)
    if lock
      gift_card.with_lock do
        success = gift_card.apply_to_order(order, gift_card_amount_cents)
        unless success
          Rails.logger.error("Failed to apply gift card #{gift_card.id} to order #{order.id}")
          raise ActiveRecord::Rollback, "Failed to apply gift card to order"
        end
      end
    else
      success = gift_card.apply_to_order(order, gift_card_amount_cents)
      unless success
        Rails.logger.error(
          "#{@log_prefix} Failed to apply gift card #{gift_card.id} to order #{order.id} (no lock)"
        )
        raise ActiveRecord::Rollback, "Failed to apply gift card to order"
      end
    end
  end
end
