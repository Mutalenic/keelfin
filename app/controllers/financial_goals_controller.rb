class FinancialGoalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_financial_goal, only: [:show, :edit, :update, :destroy, :update_progress]
  load_and_authorize_resource
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to financial_goals_path, alert: 'You are not authorized to perform this action.'
  end
  
  def index
    @active_goals = current_user.financial_goals.active.order(target_date: :asc)
    @completed_goals = current_user.financial_goals.completed.order(completion_date: :desc).limit(5)
    @overdue_goals = current_user.financial_goals.overdue.order(target_date: :asc)
    
    # Analytics
    @total_goals = @active_goals.count + @completed_goals.count + @overdue_goals.count
    @completion_rate = @total_goals > 0 ? (@completed_goals.count.to_f / @total_goals * 100).round : 0
    @total_saved = @completed_goals.where(goal_type: 'saving').sum(:current_amount)
    @total_debt_paid = @completed_goals.where(goal_type: 'debt_payment').sum(:current_amount)
  end
  
  def show
    @related_transactions = current_user.payments.where(category_id: @financial_goal.category_id)
                                      .where('created_at >= ?', @financial_goal.start_date)
                                      .order(created_at: :desc)
                                      .limit(10) if @financial_goal.category_id
    
    # Calculate trend data for chart
    @progress_history = @financial_goal.progress_history || []
    @trend_data = calculate_trend_data(@progress_history)
    
    # Recommendations based on goal progress
    @recommendations = generate_recommendations
  end
  
  def new
    @financial_goal = current_user.financial_goals.new
    @categories = current_user.categories
  end
  
  def create
    @financial_goal = current_user.financial_goals.new(financial_goal_params)
    
    if @financial_goal.save
      redirect_to financial_goals_path, notice: 'Financial goal was successfully created.'
    else
      @categories = current_user.categories
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @categories = current_user.categories
  end
  
  def update
    if @financial_goal.update(financial_goal_params)
      @financial_goal.check_completion
      redirect_to financial_goal_path(@financial_goal), notice: 'Financial goal was successfully updated.'
    else
      @categories = current_user.categories
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @financial_goal.destroy
      redirect_to financial_goals_path, notice: 'Financial goal was successfully deleted.'
    else
      redirect_to financial_goals_path, alert: 'Financial goal could not be deleted.'
    end
  end
  
  def update_progress
    if @financial_goal.update(current_amount: params[:current_amount])
      @financial_goal.check_completion
      
      # Save progress history
      history = @financial_goal.progress_history || []
      history << { date: Date.current.to_s, amount: @financial_goal.current_amount.to_f }
      @financial_goal.update(progress_history: history)
      
      redirect_to financial_goal_path(@financial_goal), notice: 'Progress updated successfully.'
    else
      redirect_to financial_goal_path(@financial_goal), alert: 'Failed to update progress.'
    end
  end
  
  private
  
  def set_financial_goal
    @financial_goal = current_user.financial_goals.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to financial_goals_path, alert: 'Financial goal not found.'
  end
  
  def financial_goal_params
    params.require(:financial_goal).permit(
      :name, :description, :target_amount, :current_amount, :start_date, 
      :target_date, :goal_type, :category_id, :recurring, :recurrence_period, 
      :priority, milestones: {}
    )
  end
  
  def calculate_trend_data(progress_history)
    return [] if progress_history.blank?
    
    # Calculate trend data for visualization
    progress_history.map do |entry|
      {
        date: entry['date'],
        amount: entry['amount'],
        percentage: ((entry['amount'].to_f / @financial_goal.target_amount) * 100).round(1)
      }
    end
  end
  
  def generate_recommendations
    recommendations = []
    
    if @financial_goal.goal_type == 'saving'
      progress = @financial_goal.progress_percentage
      days_left = @financial_goal.days_remaining
      
      if progress < 25 && days_left < 30
        recommendations << "You're behind on your savings goal. Consider increasing your daily savings by #{@financial_goal.daily_target * 1.5} to catch up."
      elsif progress < 50 && days_left < 60
        recommendations << "You're halfway to your target. Try setting aside an extra #{@financial_goal.daily_target} each week to stay on track."
      end
      
      # Add investment recommendation if saving a large amount
      if @financial_goal.target_amount > 5000
        recommendations << "Consider investing part of your savings to earn interest and reach your goal faster."
      end
    elsif @financial_goal.goal_type == 'debt_payment'
      # Debt-specific recommendations
      recommendations << "Setting up automatic payments can help ensure consistent progress on your debt repayment goal."
    end
    
    recommendations
  end
end
