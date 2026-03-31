# frozen_string_literal: true

class Admin::AuditLogsController < Admin::BaseController
  def index
    @audit_logs = AdminAuditLog.includes(:admin_user).order(occurred_at: :desc)
    @pagy, @audit_logs = pagy(:offset, @audit_logs, limit: 50)
  end
end
