class AddCouponToCartsAndOrders < ActiveRecord::Migration[7.1]
  def change
    add_reference :carts, :coupon, null: true, foreign_key: true
    add_reference :orders, :coupon, null: true, foreign_key: true
    add_column :orders, :discount_cents, :integer, default: 0
  end
end
