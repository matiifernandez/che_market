class Order < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :cart, optional: true
  belongs_to :coupon, optional: true
  belongs_to :gift_card, optional: true
  has_many :line_items, dependent: :destroy
  has_many :products, through: :line_items

  enum status: { pending: 0, paid: 1, shipped: 2, delivered: 3, cancelled: 4 }

  monetize :total_cents
  monetize :discount_cents, allow_nil: true
  monetize :gift_card_amount_cents, allow_nil: true

  validates :email, presence: true
  validates :total_cents, presence: true

  def subtotal_cents
    line_items.sum { |item| item.quantity * item.price_cents }
  end

  def subtotal
    Money.new(subtotal_cents, "USD")
  end
end
