# frozen_string_literal: true

class CheckoutAttempt < ApplicationRecord
  belongs_to :user, optional: true

  validates :ip_address, presence: true
end
