class ProductsController < ApplicationController
  def index
    @products = Product.active.includes(:category).order(created_at: :desc)

    # Search by name
    if params[:q].present?
      @query = params[:q]
      @products = @products.where("products.name ILIKE ?", "%#{@query}%")
    end

    # Filter by category
    if params[:category].present?
      @category = Category.find_by(slug: params[:category])
      @products = @products.where(category: @category) if @category
    end

    @pagy, @products = pagy(@products, items: 12)
  end
  def show
    @product = Product.active.find(params[:id])
  end
end
