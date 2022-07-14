class CategoriesController < ApplicationController
  before_action :set_category, only: %i[show update destroy]

  def index
    @user = current_user
    @categories = Category.all
  end

  def new
    @category = Category.all.where(user_id: current_user.id)
  end

  def create
    @category = Category.new(category_params)
    @category.user_id = current_user.id

    if @category.save
      redirect_to categories_path, notice: 'Category was successfully created.'
    else
      render :new, notice: 'Category was not created.'
    end
  end

  def destroy
    @user = current_user
    @category = Category.find(params[:id])
    if @category.destroy
      redirect_to categories_path, notice: 'Category was successfully deleted.'
    else
      redirect_to categories_path, notice: 'Category was not deleted.'
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.permit(:name, :icon, :user_id)
  end
end
