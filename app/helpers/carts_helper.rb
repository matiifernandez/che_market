module CartsHelper
  def cart_coupon_error_message(coupon)
    "El cupón requiere una compra mínima de #{humanized_money_with_symbol(coupon.minimum_purchase)}"
  end
end
