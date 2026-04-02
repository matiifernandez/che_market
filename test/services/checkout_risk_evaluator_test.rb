require "test_helper"

class CheckoutRiskEvaluatorTest < ActiveSupport::TestCase
  test "flags velocity by ip and user" do
    user = users(:one)
    ip = "203.0.113.10"

    fraud_config = Rails.application.config.x.fraud
    fraud_config.stub(:max_per_ip, 3) do
      fraud_config.stub(:max_per_user, 3) do
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
  end

  test "flags velocity by email" do
    email = "risk-test@example.com"
    fraud_config = Rails.application.config.x.fraud

    fraud_config.stub(:max_per_email, 3) do
      3.times do
        Order.create!(
          user: nil,
          email: email,
          status: :paid,
          total_cents: 1500,
          checkout_ip: "198.51.100.5"
        )
      end

      evaluator = CheckoutRiskEvaluator.new(user: nil, email: email, ip: "198.51.100.5", window_minutes: 60)
      result = evaluator.evaluate

      assert_includes result.flags, "velocity_email"
      assert_not result.blocked?
      assert_includes ["medium", "high"], result.level
    end
  end

  test "returns low risk when no velocity detected" do
    user = users(:one)
    ip = "203.0.113.20"
    email = "single-checkout@example.com"

    Order.create!(
      user: user,
      email: email,
      status: :paid,
      total_cents: 2000,
      checkout_ip: ip
    )

    evaluator = CheckoutRiskEvaluator.new(user: user, email: email, ip: ip, window_minutes: 60)
    result = evaluator.evaluate

    refute_includes result.flags, "velocity_ip"
    refute_includes result.flags, "velocity_user"
    refute_includes result.flags, "velocity_email"
    assert_not result.blocked?
    assert_equal "low", result.level
  end
end
