class GiftCardMailer < ApplicationMailer
  helper :application

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
      subject: t("gift_card_mailer.admin_notification.subject", amount: gift_card.formatted_initial_amount)
    )
  end

  private

  def admin_email
    ENV.fetch("ADMIN_EMAIL", "admin@chemarket.com")
  end
end
