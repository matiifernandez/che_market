require "test_helper"

class Admin::AuditLogsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @category = categories(:one)
  end

  test "creates audit log on admin product create" do
    sign_in @admin

    assert_difference "AdminAuditLog.count", 1 do
      assert_difference "Product.count", 1 do
        post admin_products_path, params: {
          product: {
            name: "Audit Product",
            category_id: @category.id,
            price: 15,
            stock: 4,
            active: true
          }
        }
      end
    end

    log = AdminAuditLog.order(:id).last
    assert_equal @admin.id, log.admin_user_id
    assert_equal "product.create", log.action
    assert_equal "Product", log.auditable_type
    assert log.auditable_id.present?
  end
end
