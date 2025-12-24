class ContactMailer < ApplicationMailer
  def contact_message(name:, email:, subject:, message:)
    @name = name
    @email = email
    @subject = subject
    @message = message

    mail(
      to: ENV.fetch('CONTACT_EMAIL', 'support@chemarket.com'),
      reply_to: email,
      subject: "[Che Market Contact] #{subject}"
    )
  end
end
