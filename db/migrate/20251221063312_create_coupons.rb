class CreateCoupons < ActiveRecord::Migration[7.1]
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.integer :discount_type, default: 0, null: false
      t.integer :discount_percentage, default: 0
      t.integer :discount_amount_cents, default: 0
      t.integer :minimum_purchase_cents
      t.integer :max_uses
      t.integer :uses_count, default: 0, null: false
      t.datetime :starts_at
      t.datetime :expires_at
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :coupons, :code, unique: true
  end
end
