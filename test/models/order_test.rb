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
    assert_includes order.errors[:status], "cannot transition from paid to pending"
  end

  test "allows updates that do not change status" do
    order = orders(:one)

    assert order.update(tracking_number: "TRACK123")
  end
end
