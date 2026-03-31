module Admin
  class ReviewsController < BaseController
    before_action :set_review, only: [:show, :approve, :reject, :destroy]

    def index
      @reviews = Review.includes(:user, :product).order(created_at: :desc)

      if params[:status].present?
        @reviews = @reviews.where(status: params[:status])
      end

      @pagy, @reviews = pagy(:offset, @reviews, limit: 20)

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
      if update_status_with_lock(:approved)
        log_admin_action!(action: "review.approve", auditable: @review, change_set: @last_review_changes)
        redirect_to admin_reviews_path, notice: t('admin.reviews.approved')
      else
        redirect_to admin_reviews_path, alert: t('admin.reviews.status_locked')
      end
    end

    def reject
      if update_status_with_lock(:rejected)
        log_admin_action!(action: "review.reject", auditable: @review, change_set: @last_review_changes)
        redirect_to admin_reviews_path, notice: t('admin.reviews.rejected')
      else
        redirect_to admin_reviews_path, alert: t('admin.reviews.status_locked')
      end
    end

    def destroy
      deleted = false
      change_set = @review.attributes
      allowed = true
      @review.with_lock do
        if @review.pending?
          @review.destroy
          deleted = true
        else
          allowed = false
        end
      end

      if deleted
        log_admin_action!(action: "review.destroy", auditable: @review, change_set: change_set)
        redirect_to admin_reviews_path, notice: t('admin.reviews.deleted')
      elsif !allowed
        redirect_to admin_reviews_path, alert: t('admin.reviews.status_locked')
      end
    end

    private

    def set_review
      @review = Review.find(params[:id])
    end

    def update_status_with_lock(new_status)
      @last_review_changes = nil
      updated = false
      @review.with_lock do
        return false unless @review.pending?

        @review.update!(status: new_status)
        @last_review_changes = @review.saved_changes
        updated = true
      end

      updated
    end
  end
end
