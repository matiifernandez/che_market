# frozen_string_literal: true

class CreateAdminAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :admin_audit_logs do |t|
      t.references :admin_user, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :auditable_type
      t.bigint :auditable_id
      t.jsonb :change_set, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.string :ip_address
      t.string :user_agent
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :admin_audit_logs, [:auditable_type, :auditable_id]
    add_index :admin_audit_logs, :action
    add_index :admin_audit_logs, :occurred_at
  end
end
