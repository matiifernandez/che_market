class ProductsController < ApplicationController
  def index
    @products = Product.available.includes(:category)

    # Search by name
    if params[:q].present?
      @query = params[:q]
      @products = @products.where("name ILIKE ?", "%#{@query}%")
    end

    # Filter by category
    if params[:category].present?
      @category = Category.find_by(slug: params[:category])
      @products = @products.where(category: @category) if @category
    end
  end
  def show
    @product = Product.find(params[:id])
  end
end
