class AddGiftCardToCartsAndOrders < ActiveRecord::Migration[7.1]
  def change
    # Cart - gift card aplicada como crédito
    add_reference :carts, :gift_card, foreign_key: true, null: true
    add_column :carts, :gift_card_amount_cents, :integer, default: 0

    # Order - registro del crédito usado
    add_reference :orders, :gift_card, foreign_key: true, null: true
    add_column :orders, :gift_card_amount_cents, :integer, default: 0
  end
end
