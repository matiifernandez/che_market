module Admin
  class ReviewsController < BaseController
    before_action :set_review, only: [:show, :approve, :reject, :destroy]

    def index
      @reviews = Review.includes(:user, :product).order(created_at: :desc)

      if params[:status].present?
        @reviews = @reviews.where(status: params[:status])
      end

      @pagy, @reviews = pagy(@reviews, items: 20)

      @stats = {
        total: Review.count,
        pending: Review.pending.count,
        approved: Review.approved.count,
        rejected: Review.rejected.count
      }
    end

    def show
    end

    def approve
      @review.approved!
      redirect_to admin_reviews_path, notice: t('admin.reviews.approved')
    end

    def reject
      @review.rejected!
      redirect_to admin_reviews_path, notice: t('admin.reviews.rejected')
    end

    def destroy
      @review.destroy
      redirect_to admin_reviews_path, notice: t('admin.reviews.deleted')
    end

    private

    def set_review
      @review = Review.find(params[:id])
    end
  end
end
