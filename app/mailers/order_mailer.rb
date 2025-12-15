class OrderMailer < ApplicationMailer
  def confirmation(order)
    @order = order
    mail(to: @order.email, subject: "Che Market - Confirmación de tu pedido ##{@order.id}")
  end
end
