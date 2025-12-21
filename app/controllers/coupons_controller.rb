class CouponsController < ApplicationController
  def apply
    @cart = current_cart

    if params[:coupon_code].blank?
      redirect_to cart_path, alert: "Ingresá un código de cupón"
      return
    end

    if @cart.apply_coupon(params[:coupon_code])
      redirect_to cart_path, notice: "Cupón aplicado: #{@cart.coupon.formatted_discount} de descuento"
    else
      redirect_to cart_path, alert: @cart.errors[:coupon].first
    end
  end

  def remove
    @cart = current_cart
    @cart.remove_coupon
    redirect_to cart_path, notice: "Cupón removido"
  end
end
