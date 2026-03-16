class Review < ApplicationRecord
  belongs_to :user
  belongs_to :product
  has_many :review_helpful_votes, dependent: :destroy
  has_many :helpful_voters, through: :review_helpful_votes, source: :user

  enum status: { pending: 0, approved: 1, rejected: 2 }

  VALID_STATUS_TRANSITIONS = {
    "pending" => %w[approved rejected],
    "approved" => [],
    "rejected" => []
  }.freeze

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :body, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :title, length: { maximum: 100 }, allow_blank: true
  validates :user_id, uniqueness: { scope: :product_id, message: :already_reviewed }
  validate :status_transition_valid, on: :update

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

  def final_status?
    !pending?
  end

  private

  def check_verified_purchase
    self.verified_purchase = user.orders
      .joins(line_items: :product)
      .where(line_items: { product_id: product_id })
      .where(status: [:paid, :shipped, :delivered])
      .exists?
  end

  def status_transition_valid
    return unless will_save_change_to_status?

    current_status_value = self.class.where(id: id).pick(:status)
    return if current_status_value.nil?

    previous_status = if current_status_value.is_a?(String)
      current_status_value
    else
      self.class.statuses.key(current_status_value)
    end
    return if previous_status.nil?

    next_status = status.to_s
    allowed = VALID_STATUS_TRANSITIONS[previous_status] || []
    return if allowed.include?(next_status)

    errors.add(:status, :invalid_transition, previous_status: previous_status, next_status: next_status)
  end
end
