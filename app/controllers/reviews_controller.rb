class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product

  def create
    @review = @product.reviews.build(review_params)
    @review.user = current_user

    if @review.save
      redirect_to product_path(@product, anchor: 'reviews'), notice: t('reviews.created')
    else
      redirect_to product_path(@product, anchor: 'reviews'), alert: @review.errors.full_messages.first
    end
  end

  def helpful
    @review = @product.reviews.find(params[:id])

    begin
      ReviewHelpfulVote.transaction do
        @review.review_helpful_votes.create!(user: current_user)
        @review.increment!(:helpful_count)
      end

      redirect_to product_path(@product, anchor: 'reviews'), notice: t('reviews.marked_helpful')
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      redirect_to product_path(@product, anchor: 'reviews'), alert: t('reviews.already_marked_helpful')
    end
  end

  private

  def set_product
    @product = Product.active.find(params[:product_id])
  end

  def review_params
    params.require(:review).permit(:rating, :title, :body)
  end
end
