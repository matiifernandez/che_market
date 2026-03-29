# frozen_string_literal: true

class CreateCspReports < ActiveRecord::Migration[7.1]
  def change
    create_table :csp_reports do |t|
      t.string :document_uri
      t.string :referrer
      t.string :violated_directive
      t.string :effective_directive
      t.string :original_policy
      t.string :blocked_uri
      t.string :source_file
      t.integer :status_code
      t.string :disposition
      t.datetime :occurred_at, null: false
      t.jsonb :raw, null: false, default: {}
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :csp_reports, :occurred_at
    add_index :csp_reports, :effective_directive
  end
end
