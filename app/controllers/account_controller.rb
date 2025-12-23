class AccountController < ApplicationController
  before_action :authenticate_user!

  def show
    @recent_orders = current_user.orders.order(created_at: :desc).limit(5)
  end

  def orders
    @orders = current_user.orders.order(created_at: :desc)
  end

  def order
    @order = current_user.orders.find(params[:id])
  end

  def edit
  end

  def update
    if current_user.update(account_params)
      redirect_to account_path, notice: t("account.profile_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end
end
