require "test_helper"

class CartsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @product = products(:one) # stock: 50
    @cart = carts(:one)
    @cart.cart_items.destroy_all
    @cart.cart_items.create!(product: @product, quantity: 3)
  end

  # ============================================
  # update_item — stock validation
  # ============================================

  test "update_item succeeds when new quantity is within available stock" do
    sign_in @user
    patch update_item_cart_path(product_id: @product.id), params: { quantity: 5 }

    assert_redirected_to cart_path
    assert_equal 5, @cart.cart_items.find_by(product: @product).quantity
  end

  test "update_item redirects with stock error when quantity exceeds available stock" do
    sign_in @user
    @product.update!(stock: 4)

    patch update_item_cart_path(product_id: @product.id), params: { quantity: 10 }

    assert_redirected_to cart_path
    assert_match /stock/, flash[:alert]
    # Quantity must not have changed
    assert_equal 3, @cart.cart_items.reload.find_by(product: @product).quantity
  end

  test "update_item removes item when quantity is zero" do
    sign_in @user
    patch update_item_cart_path(product_id: @product.id), params: { quantity: 0 }

    assert_redirected_to cart_path
    assert_nil @cart.cart_items.find_by(product: @product)
  end

  test "update_item removes item when quantity is negative" do
    sign_in @user
    patch update_item_cart_path(product_id: @product.id), params: { quantity: -1 }

    assert_redirected_to cart_path
    assert_nil @cart.cart_items.find_by(product: @product)
  end
end
