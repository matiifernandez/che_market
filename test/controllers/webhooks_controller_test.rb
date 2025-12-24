require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  include StripeTestHelper

  setup do
    @user = users(:one)
    @product = products(:one)
    @gift_card = gift_cards(:pending_card)

    # Use existing cart or create new one, clear items and add fresh ones
    @cart = @user.cart || @user.create_cart!(secret_id: SecureRandom.hex(16))
    @cart.cart_items.destroy_all
    @cart.update!(coupon: nil, gift_card: nil)
    @cart.cart_items.create!(product: @product, quantity: 2)
  end

  # ============================================
  # checkout.session.completed - Order Creation
  # ============================================

  test "creates order from checkout session completed event" do
    session_id = "cs_test_webhook_#{Time.now.to_i}"
    event = build_checkout_completed_event(
      session_id: session_id,
      amount_total: 2400,
      customer_email: @user.email,
      cart_id: @cart.id
    )

    initial_stock = @product.stock

    stub_stripe_construct_event(event) do
      assert_difference "Order.count", 1 do
        post webhooks_stripe_path, params: event.to_json, as: :json
      end
    end

    assert_response :success

    order = Order.find_by(stripe_session_id: session_id)
    assert order.present?
    assert_equal 2400, order.total_cents
    assert_equal @user.email, order.email
    assert order.paid?

    # Verify stock was decremented
    @product.reload
    assert_equal initial_stock - 2, @product.stock
  end

  test "does not create duplicate order if already exists" do
    session_id = "cs_test_existing_#{Time.now.to_i}"

    # Pre-create the order (simulating success callback beat webhook)
    Order.create!(
      stripe_session_id: session_id,
      email: @user.email,
      total_cents: 2400,
      status: :paid,
      cart: @cart
    )

    event = build_checkout_completed_event(
      session_id: session_id,
      amount_total: 2400,
      customer_email: @user.email,
      cart_id: @cart.id
    )

    stub_stripe_construct_event(event) do
      assert_no_difference "Order.count" do
        post webhooks_stripe_path, params: event.to_json, as: :json
      end
    end

    assert_response :success
  end

  test "applies coupon discount correctly" do
    coupon = coupons(:one)
    session_id = "cs_test_coupon_#{Time.now.to_i}"
    @cart.update!(coupon: coupon)

    event = build_checkout_completed_event(
      session_id: session_id,
      amount_total: 2160,
      customer_email: @user.email,
      cart_id: @cart.id,
      coupon_id: coupon.id,
      amount_discount: 240
    )

    initial_uses = coupon.uses_count

    stub_stripe_construct_event(event) do
      post webhooks_stripe_path, params: event.to_json, as: :json
    end

    assert_response :success

    order = Order.find_by(stripe_session_id: session_id)
    assert_equal coupon.id, order.coupon_id

    coupon.reload
    assert_equal initial_uses + 1, coupon.uses_count
  end

  test "applies gift card credit correctly" do
    gift_card = gift_cards(:active_card)
    session_id = "cs_test_gc_#{Time.now.to_i}"
    gift_card_amount = 1000

    event = build_checkout_completed_event(
      session_id: session_id,
      amount_total: 1400,
      customer_email: @user.email,
      cart_id: @cart.id,
      gift_card_id: gift_card.id,
      gift_card_amount_cents: gift_card_amount,
      amount_discount: gift_card_amount
    )

    initial_balance = gift_card.balance_cents

    stub_stripe_construct_event(event) do
      post webhooks_stripe_path, params: event.to_json, as: :json
    end

    assert_response :success

    order = Order.find_by(stripe_session_id: session_id)
    assert_equal gift_card.id, order.gift_card_id
    assert_equal gift_card_amount, order.gift_card_amount_cents

    gift_card.reload
    assert_equal initial_balance - gift_card_amount, gift_card.balance_cents
  end

  # ============================================
  # checkout.session.completed - Gift Card Purchase
  # ============================================

  test "activates gift card on purchase completion" do
    assert @gift_card.pending?

    event = build_gift_card_purchase_event(
      session_id: @gift_card.stripe_session_id,
      gift_card_id: @gift_card.id,
      amount: @gift_card.initial_amount_cents
    )

    stub_stripe_construct_event(event) do
      post webhooks_stripe_path, params: event.to_json, as: :json
    end

    assert_response :success

    @gift_card.reload
    assert @gift_card.active?
    assert @gift_card.delivered_at.present?
  end

  test "does not reactivate already active gift card" do
    @gift_card.update!(status: :active, delivered_at: 1.hour.ago)
    original_delivered_at = @gift_card.delivered_at

    event = build_gift_card_purchase_event(
      session_id: @gift_card.stripe_session_id,
      gift_card_id: @gift_card.id,
      amount: @gift_card.initial_amount_cents
    )

    stub_stripe_construct_event(event) do
      post webhooks_stripe_path, params: event.to_json, as: :json
    end

    assert_response :success

    @gift_card.reload
    # delivered_at should not have changed
    assert_equal original_delivered_at.to_i, @gift_card.delivered_at.to_i
  end

  # ============================================
  # Other event types
  # ============================================

  test "returns success for unhandled event types" do
    event = {
      id: "evt_test",
      type: "payment_intent.created",
      data: { object: { id: "pi_test" } }
    }

    stub_stripe_construct_event(event) do
      post webhooks_stripe_path, params: event.to_json, as: :json
    end

    assert_response :success
  end

  private

  def build_checkout_completed_event(session_id:, amount_total:, customer_email:, cart_id:, coupon_id: nil, gift_card_id: nil, gift_card_amount_cents: 0, amount_discount: 0)
    {
      id: "evt_test_#{SecureRandom.hex(8)}",
      type: "checkout.session.completed",
      data: {
        object: {
          id: session_id,
          object: "checkout.session",
          amount_total: amount_total,
          customer_details: {
            email: customer_email
          },
          metadata: {
            cart_id: cart_id.to_s,
            coupon_id: coupon_id&.to_s,
            gift_card_id: gift_card_id&.to_s,
            gift_card_amount_cents: gift_card_amount_cents.to_s
          },
          total_details: {
            amount_discount: amount_discount
          }
        }
      }
    }
  end

  def build_gift_card_purchase_event(session_id:, gift_card_id:, amount:)
    {
      id: "evt_test_gc_#{SecureRandom.hex(8)}",
      type: "checkout.session.completed",
      data: {
        object: {
          id: session_id,
          object: "checkout.session",
          amount_total: amount,
          customer_details: {
            email: "buyer@example.com"
          },
          metadata: {
            type: "gift_card",
            gift_card_id: gift_card_id.to_s
          }
        }
      }
    }
  end
end
