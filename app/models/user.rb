class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  otp_key = ENV.fetch("DEVISE_OTP_SECRET_KEY") do
    Rails.application.credentials.dig(:devise, :otp_secret_key) || Rails.application.secret_key_base
  end

  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable, :confirmable,
        :timeoutable, :two_factor_authenticatable, :two_factor_backupable,
        otp_secret_encryption_key: otp_key

  # Roles
  enum :role, { customer: 0, admin: 1, staff: 2 }

  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :nullify
  has_many :reviews, dependent: :destroy
  has_many :review_helpful_votes, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy
  has_many :wishlisted_products, through: :wishlist_items, source: :product

  serialize :otp_backup_codes, coder: JSON

  before_create :ensure_session_token

  def full_name
    [first_name, last_name].compact.join(' ').presence
  end

  def wishlisted?(product)
    wishlist_items.exists?(product: product)
  end

  def admin_access?
    admin? || staff?
  end

  def admin_write_access?
    admin?
  end

  def timeout_in
    admin_access? ? 30.minutes : 2.hours
  end

  def reset_session_token!
    update!(session_token: self.class.generate_unique_session_token)
  end

  def self.generate_unique_session_token
    SecureRandom.hex(32)
  end

  private

  def ensure_session_token
    self.session_token ||= self.class.generate_unique_session_token
  end
end
