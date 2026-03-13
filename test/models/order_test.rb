require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "allows valid status transitions" do
    order = orders(:one) # paid

    assert order.update(status: :shipped)
    assert order.shipped?
  end

  test "blocks invalid status transitions" do
    order = orders(:one) # paid

    assert_not order.update(status: :pending)
    assert_not_empty order.errors[:status]
    assert_equal :invalid_status_transition, order.errors.details[:status].first[:error]
  end

  test "allows updates that do not change status" do
    order = orders(:one)

    assert order.update(tracking_number: "TRACK123")
  end
end
