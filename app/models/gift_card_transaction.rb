class GiftCardTransaction < ApplicationRecord
  belongs_to :gift_card
  belongs_to :order, optional: true

  enum transaction_type: { redemption: 0, refund: 1 }

  monetize :amount_cents
  monetize :balance_before_cents
  monetize :balance_after_cents

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :balance_before_cents, presence: true
  validates :balance_after_cents, presence: true
end
