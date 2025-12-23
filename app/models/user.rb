class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable, :confirmable

  # Roles
  enum role: { customer: 0, admin: 1 }

  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :nullify
  has_many :reviews, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy
  has_many :wishlisted_products, through: :wishlist_items, source: :product

  def full_name
    [first_name, last_name].compact.join(' ').presence
  end

  def wishlisted?(product)
    wishlist_items.exists?(product: product)
  end
end
