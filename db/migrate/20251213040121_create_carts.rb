class CreateCarts < ActiveRecord::Migration[7.1]
  def change
    create_table :carts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :secret_id, null: false

      t.timestamps
    end
    add_index :carts, :secret_id, unique: true
  end
end
