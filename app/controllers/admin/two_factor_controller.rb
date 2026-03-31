# frozen_string_literal: true

class Admin::TwoFactorController < Admin::BaseController
  skip_before_action :require_admin_write_access!
  skip_before_action :require_admin_two_factor!

  before_action :ensure_admin_access!
  before_action :ensure_otp_secret!

  def show
    @provisioning_uri = current_user.otp_provisioning_uri(current_user.email, issuer: "Che Market")
  end

  def update
    if current_user.validate_and_consume_otp!(otp_attempt)
      current_user.otp_required_for_login = true
      current_user.generate_otp_backup_codes! if current_user.otp_backup_codes.blank?
      current_user.save!
      redirect_to admin_two_factor_path, notice: t("admin.two_factor.enabled")
    else
      flash.now[:alert] = t("admin.two_factor.invalid_code")
      @provisioning_uri = current_user.otp_provisioning_uri(current_user.email, issuer: "Che Market")
      render :show, status: :unprocessable_entity
    end
  end

  def regenerate_backup_codes
    current_user.generate_otp_backup_codes!
    current_user.save!
    redirect_to admin_two_factor_path, notice: t("admin.two_factor.backup_codes_regenerated")
  end

  def revoke_sessions
    current_user.reset_session_token!
    session[:session_token] = current_user.session_token
    redirect_to admin_two_factor_path, notice: t("admin.two_factor.sessions_revoked")
  end

  private

  def ensure_admin_access!
    return if current_user&.admin_access?

    redirect_to root_path, alert: t("admin.access_denied")
  end

  def ensure_otp_secret!
    return if current_user.otp_secret.present?

    current_user.update!(otp_secret: User.generate_otp_secret)
  end

  def otp_attempt
    params[:otp_attempt].to_s.strip
  end
end
