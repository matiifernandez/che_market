# frozen_string_literal: true

class LandingPagesController < ApplicationController
  def show
    @landing_page = LandingPage.published.find_by!(slug: params[:slug])
    @blocks = @landing_page.blocks || []

    product_ids = @blocks.filter_map do |block|
      next unless block["type"] == "product_grid"
      block["product_ids"] || []
    end.flatten.map(&:to_i).uniq
    @products_by_id = Product.available
      .with_attached_images
      .where(id: product_ids)
      .index_by(&:id)
  end
end
