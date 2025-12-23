class CreateGiftCardTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :gift_card_transactions do |t|
      t.references :gift_card, null: false, foreign_key: true
      t.references :order, foreign_key: true, null: true

      t.integer :amount_cents, null: false
      t.integer :balance_before_cents, null: false
      t.integer :balance_after_cents, null: false
      t.integer :transaction_type, default: 0, null: false
      t.text :notes

      t.timestamps
    end
  end
end
