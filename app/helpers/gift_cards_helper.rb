module GiftCardsHelper
  def formatted_gift_card_balance(gift_card)
    humanized_money_with_symbol(gift_card.balance)
  end

  def formatted_gift_card_initial_amount(gift_card)
    humanized_money_with_symbol(gift_card.initial_amount)
  end
end
