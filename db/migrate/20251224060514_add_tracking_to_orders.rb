class AddTrackingToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :tracking_number, :string
    add_column :orders, :carrier, :string
    add_column :orders, :shipped_at, :datetime
  end
end
