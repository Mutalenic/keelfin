class BudgetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_budget, only: [:edit, :update, :destroy]
  load_and_authorize_resource
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to budgets_path, alert: 'You are not authorized to perform this action.'
  end
  
  def index
    @budgets = current_user.budgets.includes(:category).order(created_at: :desc)
    @bnnb_comparison = BnnbComparisonService.new(current_user).compare
  end
  
  def new
    @budget = current_user.budgets.new
    @categories = current_user.categories
  end
  
  def create
    @budget = current_user.budgets.new(budget_params)
    if @budget.save
      redirect_to budgets_path, notice: 'Budget created successfully.'
    else
      @categories = current_user.categories
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @categories = current_user.categories
  end
  
  def update
    if @budget.update(budget_params)
      redirect_to budgets_path, notice: 'Budget updated successfully.'
    else
      @categories = current_user.categories
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @budget.destroy
    redirect_to budgets_path, notice: 'Budget deleted successfully.'
  end
  
  private
  
  def set_budget
    @budget = current_user.budgets.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to budgets_path, alert: 'Budget not found.'
  end
  
  def budget_params
    params.require(:budget).permit(:category_id, :monthly_limit, :start_date, :end_date, :inflation_adjusted)
  end
end
