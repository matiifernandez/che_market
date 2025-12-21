class Admin::CouponsController < Admin::BaseController
  before_action :set_coupon, only: %i[show edit update destroy]

  def index
    @coupons = Coupon.order(created_at: :desc)
  end

  def show; end

  def new
    @coupon = Coupon.new
  end

  def create
    @coupon = Coupon.new(coupon_params)
    if @coupon.save
      redirect_to admin_coupons_path, notice: "Cupón creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @coupon.update(coupon_params)
      redirect_to admin_coupons_path, notice: "Cupón actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @coupon.destroy
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
