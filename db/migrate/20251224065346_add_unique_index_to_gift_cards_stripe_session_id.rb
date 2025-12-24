class AddUniqueIndexToGiftCardsStripeSessionId < ActiveRecord::Migration[7.1]
  def change
    add_index :gift_cards, :stripe_session_id, unique: true, where: "stripe_session_id IS NOT NULL"
  end
end
