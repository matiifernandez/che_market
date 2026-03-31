class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin_access!
  before_action :require_admin_write_access!
  before_action :require_admin_two_factor!

  private

  def require_admin_access!
    return if current_user&.admin_access?

    redirect_to root_path, alert: t("admin.access_denied")
  end

  def require_admin_write_access!
    return if current_user&.admin_write_access?
    return unless %w[POST PATCH PUT DELETE].include?(request.request_method)

    redirect_to admin_root_path, alert: t("admin.readonly")
  end

  def require_admin_two_factor!
    return unless current_user&.admin_access?
    return if current_user.otp_required_for_login?
    return if controller_name == "two_factor"

    redirect_to admin_two_factor_path, alert: t("admin.two_factor.required")
  end
end
