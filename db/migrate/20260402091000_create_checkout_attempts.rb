# frozen_string_literal: true

class CreateCheckoutAttempts < ActiveRecord::Migration[7.1]
  def change
    create_table :checkout_attempts do |t|
      t.string :ip_address, null: false
      t.bigint :user_id
      t.string :email

      t.timestamps
    end

    add_index :checkout_attempts, :ip_address
    add_index :checkout_attempts, :user_id
    add_index :checkout_attempts, :email
    add_index :checkout_attempts, :created_at
  end
end
