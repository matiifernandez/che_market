# frozen_string_literal: true

class AddTwoFactorFieldsToUsers < ActiveRecord::Migration[7.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def change
    add_column :users, :encrypted_otp_secret, :string
    add_column :users, :encrypted_otp_secret_iv, :string
    add_column :users, :encrypted_otp_secret_salt, :string
    add_column :users, :consumed_timestep, :integer
    add_column :users, :otp_required_for_login, :boolean, default: false, null: false
    add_column :users, :otp_backup_codes, :text
    add_column :users, :session_token, :string

    add_index :users, :otp_required_for_login
    add_index :users, :session_token, unique: true

    reversible do |dir|
      dir.up do
        MigrationUser.reset_column_information
        MigrationUser.find_each do |user|
          user.update_columns(session_token: SecureRandom.hex(32))
        end
        change_column_null :users, :session_token, false
      end
    end
  end
end
