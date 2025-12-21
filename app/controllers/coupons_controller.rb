class CouponsController < ApplicationController
  def apply
    @cart = current_cart

    if params[:coupon_code].blank?
      redirect_to cart_path, alert: t("coupons.invalid")
      return
    end

    if @cart.apply_coupon(params[:coupon_code])
      redirect_to cart_path, notice: t("coupons.discount_off", discount: @cart.coupon.formatted_discount)
    else
      redirect_to cart_path, alert: @cart.errors[:coupon].first
    end
  end

  def remove
    @cart = current_cart
    @cart.remove_coupon
    redirect_to cart_path, notice: t("coupons.removed")
  end
end
