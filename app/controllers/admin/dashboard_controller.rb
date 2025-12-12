class Admin::DashboardController < Admin::BaseController
  def index
    @products_count = Product.count
    @categories_count = Category.count
    @recent_products = Product.order(created_at: :desc).limit(5)
  end
end
