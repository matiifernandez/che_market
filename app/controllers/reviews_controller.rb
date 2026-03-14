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
      vote = @review.review_helpful_votes.new(user: current_user)
      if vote.save
        redirect_to product_path(@product, anchor: 'reviews'), notice: t('reviews.marked_helpful')
      elsif duplicate_helpful_vote?(vote)
        redirect_to product_path(@product, anchor: 'reviews'), alert: t('reviews.already_marked_helpful')
      else
        redirect_to product_path(@product, anchor: 'reviews'), alert: t('reviews.helpful_error')
      end
    rescue ActiveRecord::RecordNotUnique
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

  def duplicate_helpful_vote?(record)
    return false unless record.is_a?(ReviewHelpfulVote)

    user_errors = record.errors.details[:user] || record.errors.details[:user_id] || []
    user_errors.any? { |detail| detail[:error] == :taken }
  end
end
