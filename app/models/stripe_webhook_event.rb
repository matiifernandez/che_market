# frozen_string_literal: true

class StripeWebhookEvent < ApplicationRecord
  validates :stripe_event_id, :event_type, :status, presence: true
  validates :stripe_event_id, uniqueness: true
end
