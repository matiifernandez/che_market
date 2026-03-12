class ApplicationMailer < ActionMailer::Base
  default from: -> { default_from_address }
  layout "mailer"

  private

  def admin_email
    ENV.fetch("ADMIN_EMAIL", "admin@chemarket.com")
  end

  def default_from_address
    email = ENV.fetch("MAILER_FROM_EMAIL", "noreply@example.com")
    name = ENV.fetch("MAILER_FROM_NAME", "Che Market")
    "#{name} <#{email}>"
  end
end
