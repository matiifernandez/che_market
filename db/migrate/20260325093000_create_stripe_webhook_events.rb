# frozen_string_literal: true

class CreateStripeWebhookEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :stripe_webhook_events do |t|
      t.string :stripe_event_id, null: false
      t.string :event_type, null: false
      t.boolean :livemode, null: false, default: false
      t.string :status, null: false, default: "received"
      t.datetime :processed_at
      t.text :error_message
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :stripe_webhook_events, :stripe_event_id, unique: true
    add_index :stripe_webhook_events, :status
  end
end
