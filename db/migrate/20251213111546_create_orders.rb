class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :user, null: true, foreign_key: true
      t.references :cart, null: true, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :total_cents, null: false
      t.string :stripe_session_id
      t.string :email, null: false

      t.timestamps
    end

    add_index :orders, :stripe_session_id, unique: true
    add_index :orders, :status
  end
end
