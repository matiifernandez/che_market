require "test_helper"

class Admin::PermissionsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @staff = users(:staff)
    @admin = users(:admin)
    @category = categories(:one)
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
          price_cents: 1000,
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
          price_cents: 2000,
          stock: 3,
          active: true
        }
      }
    end

    assert_redirected_to admin_products_path
  end
end
