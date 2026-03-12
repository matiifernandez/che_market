module GiftCardsHelper
  def formatted_gift_card_balance(gift_card)
    gift_card.formatted_balance
  end

  def formatted_gift_card_initial_amount(gift_card)
    gift_card.formatted_initial_amount
  end
end
