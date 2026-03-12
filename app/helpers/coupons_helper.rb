module CouponsHelper
  def formatted_coupon_discount(coupon)
    if coupon.percentage?
      "#{coupon.discount_percentage}%"
    else
      humanized_money_with_symbol(coupon.discount_amount)
    end
  end

  def formatted_coupon_minimum_purchase(coupon)
    return I18n.t("coupons.minimum_purchase.none") unless coupon.minimum_purchase_cents.present? && coupon.minimum_purchase_cents > 0
    I18n.t("coupons.minimum_purchase.label", amount: humanized_money_with_symbol(coupon.minimum_purchase))
  end
end
