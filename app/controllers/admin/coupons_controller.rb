class Admin::CouponsController < Admin::BaseController
  before_action :set_coupon, only: %i[show edit update destroy]

  def index
    @coupons = Coupon.order(created_at: :desc)
    @pagy, @coupons = pagy(:offset, @coupons, limit: 20)
  end

  def show; end

  def new
    @coupon = Coupon.new
  end

  def create
    @coupon = Coupon.new(coupon_params)
    if @coupon.save
      log_admin_action!(action: "coupon.create", auditable: @coupon, change_set: @coupon.saved_changes)
      redirect_to admin_coupons_path, notice: "Cupón creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @coupon.update(coupon_params)
      log_admin_action!(action: "coupon.update", auditable: @coupon, change_set: @coupon.saved_changes)
      redirect_to admin_coupons_path, notice: "Cupón actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    change_set = @coupon.attributes
    @coupon.destroy
    log_admin_action!(action: "coupon.destroy", auditable: @coupon, change_set: change_set) if @coupon.destroyed?
    redirect_to admin_coupons_path, notice: "Cupón eliminado."
  end

  private

  def set_coupon
    @coupon = Coupon.find(params[:id])
  end

  def coupon_params
    params.require(:coupon).permit(
      :code, :discount_type, :discount_percentage, :discount_amount,
      :minimum_purchase, :max_uses, :starts_at, :expires_at, :active
    )
  end
end
