class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :rating, null: false
      t.string :title
      t.text :body, null: false
      t.boolean :verified_purchase, default: false
      t.integer :helpful_count, default: 0
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :reviews, [:user_id, :product_id], unique: true
    add_index :reviews, :status
    add_index :reviews, :rating
  end
end
