class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: %i[show edit update destroy]

  def index
    @categories = Category.order(:name)
  end

  def show; end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to admin_categories_path(@category), notice: "Categoría creada exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path(@category), notice: "Categoría actualizada exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    redirect_to admin_categories_path, notice: "Categoría eliminada."
  end

  private

  def set_category
    @category = Category.find_by!(slug: params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :slug)
  end
end
