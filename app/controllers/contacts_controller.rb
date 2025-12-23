class ContactsController < ApplicationController
  def new
    @contact = ContactForm.new
  end

  def create
    @contact = ContactForm.new(contact_params)

    if @contact.valid?
      ContactMailer.contact_message(@contact).deliver_now
      redirect_to contact_path, notice: t('contact.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact_form).permit(:name, :email, :subject, :message)
  end
end
