require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  setup do
    @order = orders(:one)
  end

  test "confirmation" do
    mail = OrderMailer.confirmation(@order)
    assert_equal "Che Market - Confirmación de tu pedido ##{@order.id}", mail.subject
    assert_equal [@order.email], mail.to
  end

  test "admin_notification" do
    mail = OrderMailer.admin_notification(@order)
    assert_includes mail.subject, "Nueva orden ##{@order.id}"
    assert_equal [ENV.fetch("ADMIN_EMAIL", "admin@chemarket.com")], mail.to
  end

  test "shipped" do
    mail = OrderMailer.shipped(@order)
    assert_includes mail.subject, "Tu pedido ##{@order.id} ha sido enviado"
    assert_equal [@order.email], mail.to
  end
end
