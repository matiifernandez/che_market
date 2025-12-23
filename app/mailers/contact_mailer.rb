class ContactMailer < ApplicationMailer
  def contact_message(contact)
    @contact = contact
    mail(
      to: ENV.fetch('CONTACT_EMAIL', 'support@chemarket.com'),
      reply_to: contact.email,
      subject: "[Che Market Contact] #{contact.subject}"
    )
  end
end
