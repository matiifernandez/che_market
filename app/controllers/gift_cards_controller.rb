class GiftCardsController < ApplicationController
  def index
    @amounts = GiftCard::AVAILABLE_AMOUNTS.map do |cents|
      { cents: cents, money: Money.new(cents, "USD") }
    end
  end

  def new
    @amount_cents = params[:amount].to_i

    unless GiftCard.valid_amount?(@amount_cents)
      redirect_to gift_cards_path, alert: t("gift_cards.invalid_amount")
      return
    end

    @gift_card = GiftCard.new(initial_amount_cents: @amount_cents)
  end

  def create
    @gift_card = GiftCard.new(gift_card_params)
    @gift_card.purchaser = current_user
    @gift_card.purchaser_email = current_user&.email || gift_card_params[:purchaser_email]
    @gift_card.status = :pending

    unless GiftCard.valid_amount?(@gift_card.initial_amount_cents)
      redirect_to gift_cards_path, alert: t("gift_cards.invalid_amount")
      return
    end

    if @gift_card.save
      begin
        session = create_stripe_session(@gift_card)
        redirect_to session.url, allow_other_host: true
      rescue Stripe::StripeError => e
        @gift_card.destroy
        @amount_cents = @gift_card.initial_amount_cents
        flash.now[:alert] = "Stripe error: #{e.message}"
        render :new, status: :unprocessable_entity
      end
    else
      @amount_cents = @gift_card.initial_amount_cents
      render :new, status: :unprocessable_entity
    end
  end

  def success
    return unless params[:session_id]

    @gift_card = GiftCard.find_by(stripe_session_id: params[:session_id])

    # Activate gift card if webhook hasn't done it yet
    # Uses with_lock to prevent race conditions with webhook
    safely_activate_gift_card(@gift_card) if @gift_card&.pending?
  end

  def check_balance
  end

  def balance
    @gift_card = GiftCard.find_by("UPPER(code) = ?", params[:code].to_s.upcase.strip)

    if @gift_card
      render :balance_result
    else
      redirect_to check_balance_gift_cards_path, alert: t("gift_cards.not_found")
    end
  end

  private

  def safely_activate_gift_card(gift_card)
    return unless gift_card

    # Use database-level locking to prevent race condition with webhook
    gift_card.with_lock do
      # Re-check status after acquiring lock (webhook may have activated it)
      return unless gift_card.pending?

      gift_card.activate!
      GiftCardMailer.delivery(gift_card).deliver_now
      gift_card.mark_as_delivered!
      GiftCardMailer.admin_notification(gift_card).deliver_now
    end
  rescue ActiveRecord::RecordNotFound
    # Gift card was deleted (shouldn't happen, but handle gracefully)
    nil
  end

  def gift_card_params
    params.require(:gift_card).permit(
      :initial_amount_cents, :recipient_email, :recipient_name,
      :message, :purchaser_email
    )
  end

  def create_stripe_session(gift_card)
    session = Stripe::Checkout::Session.create(
      mode: "payment",
      customer_email: gift_card.purchaser_email,
      line_items: [{
        price_data: {
          currency: "usd",
          unit_amount: gift_card.initial_amount_cents,
          product_data: {
            name: "Gift Card - #{gift_card.formatted_initial_amount}",
            description: t("gift_cards.for_recipient", name: gift_card.recipient_name.presence || gift_card.recipient_email)
          }
        },
        quantity: 1
      }],
      success_url: success_gift_cards_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: gift_cards_url,
      metadata: {
        type: "gift_card",
        gift_card_id: gift_card.id
      }
    )

    gift_card.update!(stripe_session_id: session.id)
    session
  end
end
