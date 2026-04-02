# frozen_string_literal: true

class AddRiskFieldsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :risk_flags, :jsonb, null: false, default: []
    add_column :orders, :risk_level, :string
    add_column :orders, :risk_score, :integer, null: false, default: 0
    add_column :orders, :checkout_ip, :string
    add_column :orders, :checkout_user_agent, :string

    add_index :orders, :risk_level
    add_index :orders, :checkout_ip
    add_index :orders, :email
  end
end
