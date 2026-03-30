class Admin::ProductsController < Admin::BaseController
  before_action :set_product, only: %i[show edit update destroy]

  def index
    @products = Product.includes(:category).order(created_at: :desc)

    # Search by name
    if params[:q].present?
      @query = params[:q]
      @products = @products.where("name ILIKE ?", "%#{@query}%")
    end

    @pagy, @products = pagy(:offset, @products, limit: 10)
  end

  def show; end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      log_admin_action!(action: "product.create", auditable: @product, change_set: @product.saved_changes)
      redirect_to admin_products_path, notice: "Producto creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @product.update(product_params)
      log_admin_action!(action: "product.update", auditable: @product, change_set: @product.saved_changes)
      redirect_to admin_products_path, notice: "Producto actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    change_set = @product.attributes
    @product.destroy
    log_admin_action!(action: "product.destroy", auditable: @product, change_set: change_set) if @product.destroyed?
    redirect_to admin_products_path, notice: "Producto eliminado."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :description, :price, :stock, :category_id, :active, images: [])
  end
end
