class Admin::OrdersController < Admin::BaseController
  def index
    @orders = Order.order(created_at: :desc)
    @pagy, @orders = pagy(@orders, items: 20)
  end

  def show
    @order = Order.find(params[:id])
    @order.update_column(:viewed_at, Time.current) if @order.viewed_at.nil?
  end

  def update
    @order = Order.find(params[:id])
    previous_status = @order.status

    if @order.update(order_params)
      # Send shipped notification email when status changes to shipped
      if @order.shipped? && previous_status != "shipped"
        OrderMailer.shipped(@order).deliver_later
      end

      redirect_to admin_order_path(@order), notice: "Pedido actualizado."
    else
      render :show
    end
  end

  private

  def order_params
    params.require(:order).permit(:status)
  end
end
