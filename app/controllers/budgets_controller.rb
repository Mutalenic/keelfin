class BudgetsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource
  
  def index
    @budgets = current_user.budgets.includes(:category).order(created_at: :desc)
    @bnnb_comparison = BnnbComparisonService.new(current_user).compare
    
    # Prepare data for budget comparison chart
    prepare_budget_comparison_data
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
  
  def budget_params
    params.require(:budget).permit(:category_id, :monthly_limit, :start_date, :end_date, :inflation_adjusted)
  end
  
  def prepare_budget_comparison_data
    # Get current month's budgets
    current_month_start = Date.current.beginning_of_month
    current_month_end = Date.current.end_of_month
    
    # Get active budgets for the current month
    active_budgets = current_user.budgets.joins(:category)
                                .where('(start_date <= ? AND (end_date IS NULL OR end_date >= ?))', 
                                      current_month_end, current_month_start)
    
    # Prepare data for chart
    @budget_categories = []
    @budget_amounts = []
    @actual_amounts = []
    
    active_budgets.each do |budget|
      category_name = budget.category.name
      budget_amount = budget.monthly_limit
      
      # Calculate actual spending for this category in the current month
      actual_amount = current_user.payments
                                 .where(category_id: budget.category_id)
                                 .where(created_at: current_month_start..current_month_end)
                                 .sum(:amount)
      
      @budget_categories << category_name
      @budget_amounts << budget_amount
      @actual_amounts << actual_amount
    end
  end
end
