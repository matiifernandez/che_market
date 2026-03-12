class GiftCardMailer < ApplicationMailer
  helper :application
  helper :gift_cards

  def delivery(gift_card)
    @gift_card = gift_card
    mail(
      to: @gift_card.recipient_email,
      subject: t("gift_card_mailer.delivery.subject", sender: @gift_card.purchaser_name_or_email)
    )
  end

  def admin_notification(gift_card)
    @gift_card = gift_card
    mail(
      to: admin_email,
      subject: t("gift_card_mailer.admin_notification.subject", amount: formatted_gift_card_initial_amount(gift_card))
    )
  end

end
