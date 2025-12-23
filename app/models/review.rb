class Review < ApplicationRecord
  belongs_to :user
  belongs_to :product

  enum status: { pending: 0, approved: 1, rejected: 2 }

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :body, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :title, length: { maximum: 100 }, allow_blank: true
  validates :user_id, uniqueness: { scope: :product_id, message: :already_reviewed }

  scope :visible, -> { approved }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_rating, ->(rating) { where(rating: rating) }

  before_create :check_verified_purchase

  def self.average_rating
    average(:rating)&.round(1) || 0
  end

  def self.rating_distribution
    group(:rating).count.transform_keys(&:to_i)
  end

  def mark_helpful!
    increment!(:helpful_count)
  end

  private

  def check_verified_purchase
    self.verified_purchase = user.orders
      .joins(line_items: :product)
      .where(line_items: { product_id: product_id })
      .where(status: [:paid, :shipped, :delivered])
      .exists?
  end
end
