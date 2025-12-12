class ProductsController < ApplicationController
  def index
    @products = Product.available.includes(:category)

    #Filter by category if category param is present
    if params[:category].present?
      @category = Category.find_by(slug: params[:category])
      @products = @products.where(category: @category) if @category
    end
  end
  def show
    @product = Product.find(params[:id])
  end
end
