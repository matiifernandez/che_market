class Order < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :cart, optional: true
  belongs_to :coupon, optional: true
  belongs_to :gift_card, optional: true
  has_many :line_items, dependent: :destroy
  has_many :products, through: :line_items

  enum status: { pending: 0, paid: 1, shipped: 2, delivered: 3, cancelled: 4 }

  VALID_TRANSITIONS = {
    "pending" => %w[paid cancelled],
    "paid" => %w[shipped cancelled],
    "shipped" => %w[delivered],
    "delivered" => [],
    "cancelled" => []
  }.freeze

  monetize :total_cents
  monetize :discount_cents, allow_nil: true
  monetize :gift_card_amount_cents, allow_nil: true

  validates :email, presence: true
  validates :total_cents, presence: true
  validate :status_transition_valid, on: :update

  def subtotal_cents
    line_items.sum { |item| item.quantity * item.price_cents }
  end

  def subtotal
    Money.new(subtotal_cents, "USD")
  end

  def can_transition_to?(new_status)
    allowed = VALID_TRANSITIONS[status_was.to_s] || []
    allowed.include?(new_status.to_s)
  end

  private

  def status_transition_valid
    return unless will_save_change_to_status?

    previous_status = status_was
    next_status = status
    allowed = VALID_TRANSITIONS[previous_status.to_s] || []
    return if allowed.include?(next_status.to_s)

    errors.add(:status, "cannot transition from #{previous_status} to #{next_status}")
  end
end
