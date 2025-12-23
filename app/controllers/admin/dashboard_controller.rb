class Admin::DashboardController < Admin::BaseController
  def index
    # Stats cards
    @products_count = Product.count
    @categories_count = Category.count
    @orders_count = Order.count
    @total_revenue = Money.new(Order.sum(:total_cents))

    # Recent orders
    @recent_orders = Order.order(created_at: :desc).limit(5)

    # Alerts
    @low_stock_products = Product.where("stock <= ?", 5).where("stock > ?", 0).order(:stock).limit(5)
    @out_of_stock_products = Product.where(stock: 0).count
    @pending_reviews = Review.pending.count
    @pending_orders = Order.where(status: :pending).count
  end
end
