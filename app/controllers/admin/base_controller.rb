class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin_role!
  before_action :require_admin_write_access!

  private

  def require_admin_role!
    return if current_user&.admin_access?

    redirect_to root_path, alert: t("admin.access_denied")
  end

  def require_admin_write_access!
    return if current_user&.admin_write_access?
    return unless %w[POST PATCH PUT DELETE].include?(request.request_method)

    redirect_to admin_root_path, alert: t("admin.readonly")
  end
end
