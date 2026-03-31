# frozen_string_literal: true

class AdminAuditLog < ApplicationRecord
  belongs_to :admin_user, class_name: "User"
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, :occurred_at, presence: true
end
