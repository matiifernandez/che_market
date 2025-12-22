class SitemapsController < ApplicationController
  def index
    @products = Product.available
    @categories = Category.all

    respond_to do |format|
      format.xml
    end
  end
end
