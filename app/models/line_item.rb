class LineItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  monetize :price_cents

  validates :quantity, presence: true, numericality: {greater_than: 0}
  validates :price_cents, presence: true

  def subtotal
    price * quantity
  end
end
