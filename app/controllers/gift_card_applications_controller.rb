class GiftCardApplicationsController < ApplicationController
  include CartManagement

  def create
    if params[:gift_card_code].blank?
      redirect_to cart_path, alert: t("gift_cards.enter_code")
      return
    end

    if current_cart.apply_gift_card(params[:gift_card_code])
      redirect_to cart_path, notice: t("gift_cards.applied", balance: current_cart.gift_card.formatted_balance)
    else
      redirect_to cart_path, alert: current_cart.errors[:gift_card].first
    end
  end

  def destroy
    current_cart.remove_gift_card
    redirect_to cart_path, notice: t("gift_cards.removed")
  end
end
