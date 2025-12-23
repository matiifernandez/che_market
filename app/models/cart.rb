class Cart < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :coupon, optional: true
  belongs_to :gift_card, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  monetize :gift_card_amount_cents, allow_nil: true

  before_create :generate_secret_id

  def subtotal
    cart_items.sum { |item| item.quantity * item.product.price }
  end

  def subtotal_cents
    cart_items.sum { |item| item.quantity * item.product.price_cents }
  end

  def discount
    return Money.new(0, "USD") unless coupon.present?
    Money.new(discount_cents, "USD")
  end

  def discount_cents
    return 0 unless coupon.present? && coupon.valid_for_cart?(self)
    coupon.calculate_discount(subtotal_cents)
  end

  def gift_card_credit
    return Money.new(0, "USD") unless gift_card.present?
    Money.new(gift_card_amount_to_apply, "USD")
  end

  def gift_card_amount_to_apply
    return 0 unless gift_card.present? && gift_card.valid_for_use?

    # El crédito aplicable es el mínimo entre el balance disponible
    # y el total después del descuento de cupón
    subtotal_after_coupon = subtotal_cents - discount_cents
    [gift_card.balance_cents, subtotal_after_coupon].min
  end

  def total
    subtotal - discount - gift_card_credit
  end

  def total_cents
    result = subtotal_cents - discount_cents - gift_card_amount_to_apply
    [result, 0].max
  end

  def items_count
    cart_items.sum(:quantity)
  end

  def apply_coupon(code)
    coupon = Coupon.find_by("UPPER(code) = ?", code.to_s.upcase.strip)

    if coupon.nil?
      errors.add(:coupon, I18n.t("coupons.not_found"))
      return false
    end

    unless coupon.valid_for_cart?(self)
      if coupon.minimum_purchase_cents.present? && subtotal_cents < coupon.minimum_purchase_cents
        min = ActionController::Base.helpers.humanized_money_with_symbol(coupon.minimum_purchase)
        errors.add(:coupon, I18n.t("coupons.minimum_required", amount: min))
      elsif !coupon.active?
        errors.add(:coupon, I18n.t("coupons.not_active"))
      else
        errors.add(:coupon, I18n.t("coupons.invalid"))
      end
      return false
    end

    update(coupon: coupon)
    true
  end

  def remove_coupon
    update(coupon: nil)
  end

  def apply_gift_card(code)
    gift_card = GiftCard.find_by("UPPER(code) = ?", code.to_s.upcase.strip)

    if gift_card.nil?
      errors.add(:gift_card, I18n.t("gift_cards.not_found"))
      return false
    end

    unless gift_card.valid_for_use?
      if gift_card.expired?
        errors.add(:gift_card, I18n.t("gift_cards.expired"))
      elsif gift_card.balance_cents.zero?
        errors.add(:gift_card, I18n.t("gift_cards.no_balance"))
      else
        errors.add(:gift_card, I18n.t("gift_cards.invalid"))
      end
      return false
    end

    update(gift_card: gift_card)
    true
  end

  def remove_gift_card
    update(gift_card: nil, gift_card_amount_cents: 0)
  end

  def add_product(product, quantity = 1)
    item = cart_items.find_by(product: product)
    if item
      item.quantity += quantity
    else
      item = cart_items.build(product: product, quantity: quantity)
    end

    item.save!
    item
  end

  def remove_product(product)
    cart_items.find_by(product: product)&.destroy
  end

  private

  def generate_secret_id
    self.secret_id = SecureRandom.urlsafe_base64(16)
  end
end
