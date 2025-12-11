class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.references :category, null: false, foreign_key: true
      t.integer :price_cents, null: false, default: 0
      t.integer :stock, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :products, :active
  end
end
