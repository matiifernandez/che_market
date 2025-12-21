class Coupon < ApplicationRecord
  has_many :carts
  has_many :orders

  enum discount_type: { percentage: 0, fixed_amount: 1 }

  monetize :discount_amount_cents, allow_nil: true
  monetize :minimum_purchase_cents, allow_nil: true

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :discount_percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, if: :percentage?
  validates :discount_amount_cents, numericality: { greater_than: 0 }, if: :fixed_amount?

  before_validation :normalize_code

  scope :active, -> { where(active: true) }
  scope :valid_now, -> {
    where("starts_at IS NULL OR starts_at <= ?", Time.current)
      .where("expires_at IS NULL OR expires_at >= ?", Time.current)
  }
  scope :available, -> { active.valid_now }

  def valid_for_cart?(cart)
    return false unless active?
    return false if expired?
    return false if not_yet_started?
    return false if usage_limit_reached?
    return false if below_minimum_purchase?(cart)
    true
  end

  def calculate_discount(subtotal_cents)
    if percentage?
      (subtotal_cents * discount_percentage / 100.0).round
    else
      [discount_amount_cents, subtotal_cents].min
    end
  end

  def increment_usage!
    increment!(:uses_count)
  end

  def formatted_discount
    if percentage?
      "#{discount_percentage}%"
    else
      ActionController::Base.helpers.humanized_money_with_symbol(discount_amount)
    end
  end

  private

  def normalize_code
    self.code = code.to_s.upcase.strip
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def not_yet_started?
    starts_at.present? && starts_at > Time.current
  end

  def usage_limit_reached?
    max_uses.present? && uses_count >= max_uses
  end

  def below_minimum_purchase?(cart)
    minimum_purchase_cents.present? && cart.subtotal_cents < minimum_purchase_cents
  end
end
