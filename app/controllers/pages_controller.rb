class PagesController < ApplicationController
  def home
    @featured_products = Product.available
      .includes(images_attachments: :blob)
      .limit(4)
  end

  def terms
  end

  def privacy
  end
end
