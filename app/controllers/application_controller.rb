class ApplicationController < ActionController::Base
  include Pagy::Method
  include CartManagement

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :verify_session_token, if: :user_signed_in?
  after_action :transfer_cart_to_user, if: :user_signed_in?

  private

  def set_locale
    I18n.locale = params[:locale] || session[:locale] || I18n.default_locale
    session[:locale] = I18n.locale
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end

  def verify_session_token
    warden = request.env["warden"]
    stored_token = warden&.session(:user)&.dig(:session_token) || session[:session_token]
    return if stored_token.present? && stored_token == current_user.session_token

    sign_out(current_user)
    redirect_to new_user_session_path, alert: t("auth.session_expired")
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end
end
