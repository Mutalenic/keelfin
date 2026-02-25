class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: %i[show edit update destroy]
  load_and_authorize_resource

  def index
    @user = current_user
    @categories = current_user.categories.includes(:payments).ordered_by_name
    
    # Group categories by type for better organization
    @grouped_categories = @categories.group_by(&:category_type)
  end

  def new
    @category = current_user.categories.new
    @category_types = ['groceries', 'fixed', 'variable', 'discretionary']
    @preset_categories = Category.preset_categories
  end

  def edit
    @category_types = ['groceries', 'fixed', 'variable', 'discretionary']
  end

  def create
    @category = current_user.categories.new(category_params)

    if @category.save
      redirect_to categories_path, notice: 'Category was successfully created.'
    else
      @category_types = ['groceries', 'fixed', 'variable', 'discretionary']
      @preset_categories = Category.preset_categories
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @payments = @category.payments.order(created_at: :desc).limit(10)
    @total_amount = @category.total_amount
    @monthly_average = @category.monthly_average
    @percentage_of_total = @category.percentage_of_total_spending
  end

  def update
    if @category.update(category_params)
      redirect_to category_path(@category), notice: 'Category was successfully updated.'
    else
      @category_types = ['groceries', 'fixed', 'variable', 'discretionary']
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
  
  def add_preset
    authorize! :create, Category
    
    preset_name = params[:preset_name]
    preset = Category.preset_categories.find { |p| p[:name] == preset_name }
    
    if preset.present?
      @category = current_user.categories.new(preset)
      if @category.save
        redirect_to categories_path, notice: "#{preset_name} category was successfully added."
      else
        redirect_to new_category_path, alert: @category.errors.full_messages.join(', ')
      end
    else
      redirect_to new_category_path, alert: 'Preset category not found.'
    end
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to categories_path, alert: 'Category not found.'
  end

  def category_params
    params.require(:category).permit(:name, :icon, :description, :color, :icon_name, :category_type)
  end
end
