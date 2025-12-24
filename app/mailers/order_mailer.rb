class OrderMailer < ApplicationMailer
  helper :application
  helper :tracking

  def confirmation(order)
    @order = order
    mail(to: @order.email, subject: "Che Market - Confirmación de tu pedido ##{@order.id}")
  end

  def admin_notification(order)
    @order = order
    mail(to: admin_email, subject: "🧉 Nueva orden ##{@order.id} - $#{format_price(@order.total_cents)}")
  end

  def shipped(order)
    @order = order
    mail(to: @order.email, subject: "Che Market - ¡Tu pedido ##{@order.id} ha sido enviado! 📦")
  end

  def admin_email
    ENV.fetch("ADMIN_EMAIL", "admin@chemarket.com")
  end

  def format_price(cents)
    "%.2f" % (cents / 100.0)
  end
end
