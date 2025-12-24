require "test_helper"

class CheckoutsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include StripeTestHelper

  setup do
    @user = users(:one)
    @product = products(:one)
    @coupon = coupons(:one)

    # Use existing cart or create new one, clear items
    @cart = @user.cart || @user.create_cart!(secret_id: SecureRandom.hex(16))
    @cart.cart_items.destroy_all
    @cart.update!(coupon: nil, gift_card: nil)
  end

  # ============================================
  # CREATE - Initiating checkout
  # ============================================

  test "create redirects to cart if cart is empty" do
    sign_in @user

    post checkout_path
    assert_redirected_to cart_path
    assert_equal "Tu carrito está vacío", flash[:alert]
  end

  test "create redirects to cart if product out of stock" do
    sign_in @user
    @cart.cart_items.create!(product: @product, quantity: 1)
    @product.update!(stock: 0)

    post checkout_path
    assert_redirected_to cart_path
    assert_match /No hay suficiente stock/, flash[:alert]
  end

  test "create redirects to Stripe checkout with valid cart" do
    sign_in @user
    @cart.cart_items.create!(product: @product, quantity: 1)

    mock_session = OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/pay/cs_test_123")

    stub_stripe_session_create(mock_session) do
      post checkout_path
      assert_response :redirect
    end
  end

  # ============================================
  # SUCCESS - Order completion
  # ============================================

  test "success finds existing order created by webhook" do
    sign_in @user
    order = Order.create!(
      stripe_session_id: "cs_test_existing_order",
      email: @user.email,
      total_cents: 1200,
      status: :paid
    )

    get success_checkout_path(session_id: order.stripe_session_id)

    assert_response :success
  end

  test "success creates order if webhook has not processed yet" do
    sign_in @user
    @cart.cart_items.create!(product: @product, quantity: 1)

    session_id = "cs_test_new_session_#{Time.now.to_i}"
    stripe_session = mock_stripe_session_object(
      session_id,
      amount_total: 1200,
      customer_email: @user.email,
      cart_id: @cart.id
    )

    stub_stripe_session_retrieve(stripe_session) do
      assert_difference "Order.count", 1 do
        get success_checkout_path(session_id: session_id)
      end
    end

    assert_response :success
    order = Order.find_by(stripe_session_id: session_id)
    assert order.present?
    assert_equal 1200, order.total_cents
  end

  test "success handles race condition gracefully" do
    sign_in @user
    @cart.cart_items.create!(product: @product, quantity: 1)

    session_id = "cs_test_race_#{Time.now.to_i}"

    # Pre-create order (simulating webhook beat success callback)
    Order.create!(
      stripe_session_id: session_id,
      email: @user.email,
      total_cents: 1200,
      status: :paid,
      cart: @cart
    )

    stripe_session = mock_stripe_session_object(
      session_id,
      amount_total: 1200,
      customer_email: @user.email,
      cart_id: @cart.id
    )

    stub_stripe_session_retrieve(stripe_session) do
      assert_no_difference "Order.count" do
        get success_checkout_path(session_id: session_id)
      end
    end

    assert_response :success
  end

  test "success with order_id param for gift card purchases" do
    sign_in @user
    order = Order.create!(
      email: @user.email,
      total_cents: 0,
      status: :paid
    )

    get success_checkout_path(order_id: order.id)

    assert_response :success
  end

  test "success clears cart after successful order" do
    sign_in @user
    @cart.cart_items.create!(product: @product, quantity: 2)

    assert @cart.cart_items.any?

    session_id = "cs_test_clear_cart_#{Time.now.to_i}"
    stripe_session = mock_stripe_session_object(
      session_id,
      amount_total: 2400,
      customer_email: @user.email,
      cart_id: @cart.id
    )

    stub_stripe_session_retrieve(stripe_session) do
      get success_checkout_path(session_id: session_id)
    end

    @cart.reload
    assert @cart.cart_items.empty?
  end

  test "success decrements product stock" do
    sign_in @user
    initial_stock = @product.stock
    @cart.cart_items.create!(product: @product, quantity: 2)

    session_id = "cs_test_stock_#{Time.now.to_i}"
    stripe_session = mock_stripe_session_object(
      session_id,
      amount_total: 2400,
      customer_email: @user.email,
      cart_id: @cart.id
    )

    stub_stripe_session_retrieve(stripe_session) do
      get success_checkout_path(session_id: session_id)
    end

    @product.reload
    assert_equal initial_stock - 2, @product.stock
  end

  # ============================================
  # CANCEL
  # ============================================

  test "cancel renders cancel page" do
    get cancel_checkout_path
    assert_response :success
  end

  # ============================================
  # Discount handling
  # ============================================

  test "success applies coupon discount correctly" do
    sign_in @user
    @cart.cart_items.create!(product: @product, quantity: 1)
    @cart.update!(coupon: @coupon)

    session_id = "cs_test_coupon_#{Time.now.to_i}"
    stripe_session = mock_stripe_session_object(
      session_id,
      amount_total: 1080,
      customer_email: @user.email,
      cart_id: @cart.id,
      coupon_id: @coupon.id,
      amount_discount: 120
    )

    stub_stripe_session_retrieve(stripe_session) do
      get success_checkout_path(session_id: session_id)
    end

    assert_response :success
    order = Order.find_by(stripe_session_id: session_id)
    assert order.present?
    assert_equal @coupon.id, order.coupon_id
  end

  test "success applies gift card credit correctly" do
    sign_in @user
    @cart.cart_items.create!(product: @product, quantity: 1)
    gift_card = gift_cards(:active_card)
    @cart.update!(gift_card: gift_card)

    gift_card_amount = 500
    initial_balance = gift_card.balance_cents

    session_id = "cs_test_gc_#{Time.now.to_i}"
    stripe_session = mock_stripe_session_object(
      session_id,
      amount_total: 700,
      customer_email: @user.email,
      cart_id: @cart.id,
      gift_card_id: gift_card.id,
      gift_card_amount_cents: gift_card_amount,
      amount_discount: gift_card_amount
    )

    stub_stripe_session_retrieve(stripe_session) do
      get success_checkout_path(session_id: session_id)
    end

    assert_response :success
    order = Order.find_by(stripe_session_id: session_id)
    assert order.present?
    assert_equal gift_card.id, order.gift_card_id
    assert_equal gift_card_amount, order.gift_card_amount_cents

    gift_card.reload
    assert_equal initial_balance - gift_card_amount, gift_card.balance_cents
  end

  private

  def mock_stripe_session_object(id, amount_total:, customer_email:, cart_id:, coupon_id: nil, gift_card_id: nil, gift_card_amount_cents: 0, amount_discount: 0)
    metadata = {
      "cart_id" => cart_id.to_s,
      "coupon_id" => coupon_id&.to_s,
      "gift_card_id" => gift_card_id&.to_s,
      "gift_card_amount_cents" => gift_card_amount_cents.to_s
    }

    customer_details = OpenStruct.new(email: customer_email)
    total_details = OpenStruct.new(amount_discount: amount_discount)

    OpenStruct.new(
      id: id,
      amount_total: amount_total,
      metadata: metadata,
      customer_details: customer_details,
      total_details: total_details
    )
  end
end
