class ApplicationController < ActionController::Base
  include CartManagement

  before_action :set_locale
  after_action :transfer_cart_to_user, if: :user_signed_in?

  private

  def set_locale
    I18n.locale = params[:locale] || session[:locale] || I18n.default_locale
    session[:locale] = I18n.locale
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end
end
