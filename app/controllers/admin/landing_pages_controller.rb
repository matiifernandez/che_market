# frozen_string_literal: true

class Admin::LandingPagesController < Admin::BaseController
  before_action :set_landing_page, only: [:show, :edit, :update, :destroy]

  def index
    @landing_pages = LandingPage.order(created_at: :desc)
  end

  def show
  end

  def new
    @landing_page = LandingPage.new
  end

  def edit
  end

  def create
    @landing_page = LandingPage.new(landing_page_params)
    if @landing_page.save
      redirect_to admin_landing_page_path(@landing_page), notice: "Landing page creada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @landing_page.update(landing_page_params)
      redirect_to admin_landing_page_path(@landing_page), notice: "Landing page actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @landing_page.destroy
    redirect_to admin_landing_pages_path, notice: "Landing page eliminada."
  end

  private

  def set_landing_page
    @landing_page = LandingPage.find(params[:id])
  end

  def landing_page_params
    params.require(:landing_page).permit(
      :title,
      :slug,
      :meta_title,
      :meta_description,
      :hero_title,
      :hero_subtitle,
      :hero_cta_text,
      :hero_cta_url,
      :published,
      :blocks_json
    )
  end
end
