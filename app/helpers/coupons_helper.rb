module CouponsHelper
  def formatted_coupon_discount(coupon)
    if coupon.discount_type == "percentage"
      "#{coupon.discount_percentage}%"
    else
      humanized_money_with_symbol(coupon.discount_amount)
    end
  end

  def formatted_coupon_minimum_purchase(coupon)
    return "Sin mínimo" unless coupon.minimum_purchase_cents.present? && coupon.minimum_purchase_cents > 0
    humanized_money_with_symbol(coupon.minimum_purchase)
  end
end
