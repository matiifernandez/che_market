require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "requires category" do
    product = Product.new(
      name: "Test Product",
      price_cents: 1000,
      stock: 5,
      active: true
    )

    assert_not product.valid?
    assert product.errors[:category].any?
  end
end
