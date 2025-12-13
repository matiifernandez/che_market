class Order < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :cart, optional: true

  enum status: { pending: 0, paid: 1, shipped: 2, delivered: 3, cancelled: 4 }

  monetize :total_cents

  validates :email, presence: true
  validates :total_cents, presence: true
end
