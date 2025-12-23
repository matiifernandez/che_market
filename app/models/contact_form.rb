class ContactForm
  include ActiveModel::Model

  attr_accessor :name, :email, :subject, :message

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true
  validates :message, presence: true, length: { minimum: 10 }
end
