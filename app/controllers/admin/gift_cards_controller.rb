class Admin::GiftCardsController < Admin::BaseController
  def index
    @gift_cards = GiftCard.order(created_at: :desc)

    if params[:status].present?
      @gift_cards = @gift_cards.where(status: params[:status])
    end

    if params[:search].present?
      search = "%#{params[:search]}%"
      @gift_cards = @gift_cards.where(
        "code ILIKE :search OR recipient_email ILIKE :search OR purchaser_email ILIKE :search",
        search: search
      )
    end

    @gift_cards = @gift_cards.limit(50)
  end

  def show
    @gift_card = GiftCard.find(params[:id])
    @transactions = @gift_card.gift_card_transactions.order(created_at: :desc)
  end

  def cancel
    @gift_card = GiftCard.find(params[:id])

    if @gift_card.cancelled?
      redirect_to admin_gift_card_path(@gift_card), alert: t("admin.gift_cards.already_cancelled")
      return
    end

    @gift_card.update!(status: :cancelled)
    redirect_to admin_gift_card_path(@gift_card), notice: t("admin.gift_cards.cancelled_success")
  end

  def resend_email
    @gift_card = GiftCard.find(params[:id])

    unless @gift_card.active? || @gift_card.depleted?
      redirect_to admin_gift_card_path(@gift_card), alert: t("admin.gift_cards.cannot_resend")
      return
    end

    GiftCardMailer.delivery(@gift_card).deliver_later
    redirect_to admin_gift_card_path(@gift_card), notice: t("admin.gift_cards.email_resent")
  end
end
