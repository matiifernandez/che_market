module CouponsHelper
  def formatted_coupon_discount(coupon)
    coupon.formatted_discount
  end

  def formatted_coupon_minimum_purchase(coupon)
    return I18n.t("coupons.minimum_purchase.none") unless coupon.minimum_purchase_cents.present? && coupon.minimum_purchase_cents > 0
    I18n.t("coupons.minimum_purchase.label", amount: coupon.minimum_purchase.format)
  end
end
