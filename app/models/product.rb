class Product < ApplicationRecord
  belongs_to :category, optional: true
  has_rich_text :description
  has_many_attached :images
  has_many :cart_items, dependent: :destroy
  has_many :line_items, dependent: :nullify

  # Money rails
  monetize :price_cents

  # Validations
  validates :name, presence: true
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :in_stock, -> { where('stock > 0') }
  scope :available, -> { active.in_stock }

end
