class AddViewedAtToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :viewed_at, :datetime
  end
end
