class WishlistController < ApplicationController
  before_action :authenticate_user!

  def show
    @wishlist_items = current_user.wishlist_items.includes(:product).recent
  end

  def add
    @product = Product.find(params[:product_id])

    if current_user.wishlisted?(@product)
      redirect_back fallback_location: product_path(@product), alert: t('wishlist.already_added')
    else
      current_user.wishlist_items.create(product: @product)
      redirect_back fallback_location: product_path(@product), notice: t('wishlist.added')
    end
  end

  def remove
    @wishlist_item = current_user.wishlist_items.find_by(product_id: params[:product_id])

    if @wishlist_item
      @wishlist_item.destroy
      redirect_back fallback_location: wishlist_path, notice: t('wishlist.removed')
    else
      redirect_back fallback_location: wishlist_path, alert: t('wishlist.not_found')
    end
  end
end
