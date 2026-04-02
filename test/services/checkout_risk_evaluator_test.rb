require "test_helper"

class CheckoutRiskEvaluatorTest < ActiveSupport::TestCase
  test "flags velocity by ip and user" do
    user = users(:one)
    ip = "203.0.113.10"

    3.times do
      Order.create!(
        user: user,
        email: user.email,
        status: :paid,
        total_cents: 1000,
        checkout_ip: ip
      )
    end

    evaluator = CheckoutRiskEvaluator.new(user: user, email: user.email, ip: ip, window_minutes: 60)
    result = evaluator.evaluate

    assert_includes result.flags, "velocity_ip"
    assert_includes result.flags, "velocity_user"
    assert result.blocked?
    assert_equal "high", result.level
  end
end
