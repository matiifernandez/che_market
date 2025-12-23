class CreateGiftCards < ActiveRecord::Migration[7.1]
  def change
    create_table :gift_cards do |t|
      # Código único
      t.string :code, null: false

      # Montos (money-rails pattern)
      t.integer :initial_amount_cents, null: false
      t.integer :balance_cents, null: false

      # Comprador
      t.references :purchaser, foreign_key: { to_table: :users }, null: true
      t.string :purchaser_email, null: false

      # Destinatario
      t.string :recipient_email, null: false
      t.string :recipient_name
      t.text :message

      # Estado y fechas
      t.integer :status, default: 0, null: false
      t.datetime :purchased_at
      t.datetime :delivered_at
      t.datetime :expires_at
      t.datetime :first_used_at

      # Stripe
      t.string :stripe_session_id

      t.timestamps
    end

    add_index :gift_cards, :code, unique: true
    add_index :gift_cards, :recipient_email
    add_index :gift_cards, :purchaser_email
    add_index :gift_cards, :status
  end
end
