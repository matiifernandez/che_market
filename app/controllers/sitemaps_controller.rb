class SitemapsController < ApplicationController
  def index
    @products = Product.available
    @categories = Category.all
    @landing_pages = LandingPage.published

    respond_to do |format|
      format.xml
    end
  end
end
