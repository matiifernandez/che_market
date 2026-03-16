require "test_helper"

class CouponTest < ActiveSupport::TestCase
  test "clears fixed amount when percentage coupon" do
    coupon = Coupon.new(
      code: "PERCENT10",
      discount_type: :percentage,
      discount_percentage: 10,
      discount_amount_cents: 500
    )

    assert coupon.valid?
    assert_nil coupon.discount_amount_cents
  end

  test "clears percentage when fixed amount coupon" do
    coupon = Coupon.new(
      code: "FIXED5",
      discount_type: :fixed_amount,
      discount_amount_cents: 500,
      discount_percentage: 10
    )

    assert coupon.valid?
    assert_nil coupon.discount_percentage
  end

  test "requires percentage value for percentage coupons" do
    coupon = Coupon.new(code: "PCT", discount_type: :percentage)

    assert_not coupon.valid?
    assert coupon.errors[:discount_percentage].any?
  end
end
