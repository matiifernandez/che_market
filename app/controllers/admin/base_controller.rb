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

  def log_admin_action!(action:, auditable: nil, change_set: nil, metadata: {})
    return unless current_user

    AdminAuditLog.create!(
      admin_user: current_user,
      action: action,
      auditable: auditable,
      change_set: change_set || {},
      metadata: {
        path: request.fullpath,
        method: request.request_method,
        request_id: request.request_id
      }.merge(metadata || {}),
      ip_address: request.remote_ip.to_s,
      user_agent: request.user_agent.to_s,
      occurred_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error(
      "Failed to log admin action #{action.inspect} for user #{current_user&.id}: " \
      "#{e.class} - #{e.message}"
    )
  end
end
