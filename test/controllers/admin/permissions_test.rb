require "test_helper"

class Admin::PermissionsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @staff = users(:staff)
    @admin = users(:admin)
    @category = categories(:one)

    @staff.update!(otp_required_for_login: true)
    @admin.update!(otp_required_for_login: true)
  end

  test "staff can view admin pages" do
    sign_in @staff
    get admin_products_path
    assert_response :success
  end

  test "staff cannot perform admin write actions" do
    sign_in @staff

    assert_no_difference "Product.count" do
      post admin_products_path, params: {
        product: {
          name: "Test Product",
          category_id: @category.id,
          price: 10,
          stock: 5,
          active: true
        }
      }
    end

    assert_redirected_to admin_root_path
    assert_equal I18n.t("admin.readonly"), flash[:alert]
  end

  test "admin can perform admin write actions" do
    sign_in @admin

    assert_difference "Product.count", 1 do
      post admin_products_path, params: {
        product: {
          name: "Admin Product",
          category_id: @category.id,
          price: 20,
          stock: 3,
          active: true
        }
      }
    end

    assert_redirected_to admin_products_path
  end

  test "staff viewing order does not mark as viewed" do
    sign_in @staff
    order = orders(:one)
    order.update!(viewed_at: nil)

    get admin_order_path(order)
    assert_response :success
    assert_nil order.reload.viewed_at
  end
end
