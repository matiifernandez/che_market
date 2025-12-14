class Admin::OrdersController < Admin::BaseController
  def index
    @orders = Order.order(created_at: :desc)
  end

  def show
    @order = Order.find(params[:id])
  end

  def update
    @order = Order.find(params[:id])
    if @order.update(order_params)
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
