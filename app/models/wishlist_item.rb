class WishlistItem < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :user_id, uniqueness: { scope: :product_id, message: :already_in_wishlist }

  scope :recent, -> { order(created_at: :desc) }
end
