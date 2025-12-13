class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  before_create :generate_secret_id

  def total
    cart_items.sum { |item| item.quantity * item.product.price }
  end

  def items_count
    cart_items.sum(:quantity)
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
