class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: %i[show edit update destroy]
  load_and_authorize_resource

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to categories_path, alert: 'You are not authorized to perform this action.'
  end

  def index
    @user = current_user
    @categories = current_user.categories.includes(:payments)
  end

  def new
    @category = current_user.categories.new
  end

  def edit
  end

  def create
    @category = current_user.categories.new(category_params)

    if @category.save
      redirect_to categories_path, notice: 'Category was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: 'Category was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
      redirect_to categories_path, notice: 'Category was successfully deleted.'
    else
      redirect_to categories_path, alert: 'Category could not be deleted.'
    end
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to categories_path, alert: 'Category not found.'
  end

  def category_params
    params.require(:category).permit(:name, :icon)
  end
end
