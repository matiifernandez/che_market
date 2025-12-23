class GiftCard < ApplicationRecord
  belongs_to :purchaser, class_name: "User", optional: true
  has_many :gift_card_transactions, dependent: :destroy
  has_many :orders
  has_many :carts

  enum status: {
    pending: 0,
    active: 1,
    depleted: 2,
    expired: 3,
    cancelled: 4
  }

  monetize :initial_amount_cents
  monetize :balance_cents

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :initial_amount_cents, presence: true,
            numericality: { greater_than: 0, only_integer: true }
  validates :balance_cents, presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  validates :purchaser_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :recipient_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_validation :generate_code, on: :create
  before_validation :set_initial_balance, on: :create
  before_validation :normalize_emails

  scope :available, -> { active.where("balance_cents > 0") }
  scope :by_recipient, ->(email) { where("LOWER(recipient_email) = ?", email.downcase) }

  AVAILABLE_AMOUNTS = [2000, 5000, 10000].freeze # $20, $50, $100 en centavos

  def self.valid_amount?(amount_cents)
    AVAILABLE_AMOUNTS.include?(amount_cents.to_i)
  end

  def valid_for_use?
    active? && !expired? && balance_cents > 0
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def apply_to_order(order, amount_cents)
    return false unless valid_for_use?
    return false if amount_cents > balance_cents
    return false if amount_cents <= 0

    transaction do
      new_balance = balance_cents - amount_cents

      gift_card_transactions.create!(
        order: order,
        amount_cents: amount_cents,
        balance_before_cents: balance_cents,
        balance_after_cents: new_balance,
        transaction_type: :redemption
      )

      update!(
        balance_cents: new_balance,
        first_used_at: first_used_at || Time.current,
        status: new_balance.zero? ? :depleted : :active
      )
    end

    true
  end

  def refund_to_card(order, amount_cents, notes: nil)
    return false if amount_cents <= 0

    transaction do
      new_balance = balance_cents + amount_cents

      gift_card_transactions.create!(
        order: order,
        amount_cents: amount_cents,
        balance_before_cents: balance_cents,
        balance_after_cents: new_balance,
        transaction_type: :refund,
        notes: notes
      )

      update!(
        balance_cents: new_balance,
        status: :active
      )
    end

    true
  end

  def activate!
    update!(
      status: :active,
      purchased_at: Time.current
    )
  end

  def mark_as_delivered!
    update!(delivered_at: Time.current)
  end

  def formatted_balance
    ActionController::Base.helpers.humanized_money_with_symbol(balance)
  end

  def formatted_initial_amount
    ActionController::Base.helpers.humanized_money_with_symbol(initial_amount)
  end

  def purchaser_name_or_email
    purchaser&.first_name.presence || purchaser_email.split("@").first
  end

  private

  def generate_code
    return if code.present?

    loop do
      self.code = "CHE-#{SecureRandom.alphanumeric(4).upcase}-#{SecureRandom.alphanumeric(4).upcase}-#{SecureRandom.alphanumeric(4).upcase}"
      break unless GiftCard.exists?(code: code)
    end
  end

  def set_initial_balance
    self.balance_cents = initial_amount_cents if balance_cents.blank? || balance_cents.zero?
  end

  def normalize_emails
    self.purchaser_email = purchaser_email&.downcase&.strip
    self.recipient_email = recipient_email&.downcase&.strip
  end
end
