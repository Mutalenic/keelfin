class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  HIGH_CATEGORY_SPENDING_THRESHOLD = 40
  
  def index
    # Date range filtering (default to current month)
    @start_date = parse_date_param(params[:start_date]) || Date.current.beginning_of_month
    @end_date = parse_date_param(params[:end_date]) || Date.current.end_of_month
    @date_range = @start_date..@end_date
    
    # Core financial data
    @total_spending = current_user.total_spending(@date_range)
    @spending_by_category = current_user.spending_by_category(@date_range)
    @burn_rate = current_user.burn_rate
    @projected_balance = current_user.projected_month_end_balance
    
    # Financial health analysis
    @debt_analysis = DebtAnalysisService.new(current_user).analyze
    @bnnb_comparison = BnnbComparisonService.new(current_user).compare
    
    # Financial goals
    @active_goals = current_user.financial_goals.in_progress.order(target_date: :asc).limit(3)
    @goals_progress = calculate_goals_progress
    
    # Investments data
    @investments = current_user.investments.active.order(current_value: :desc).limit(3)
    @total_invested = @investments.sum(:current_value)
    @investment_return = calculate_investment_return
    @portfolio_allocation = calculate_portfolio_allocation
    
    # Recurring transactions
    @upcoming_recurring = current_user.recurring_transactions.active
                                     .where('next_occurrence <= ?', 7.days.from_now)
                                     .order(next_occurrence: :asc)
                                     .limit(3)
    
    # Recent activity
    @recent_payments = current_user.payments.includes(:category).recent.limit(10)
    
    # Economic indicators
    @latest_economic_data = EconomicIndicator.latest
    
    # Monthly spending trend data
    @monthly_spending_trend = calculate_monthly_spending_trend
    
    # Insights and recommendations
    @financial_insights = generate_insights
  end
  
  private
  
  def calculate_goals_progress
    total_goals = current_user.financial_goals.count
    return 0 if total_goals.zero?
    
    completed_goals = current_user.financial_goals.completed.count
    (completed_goals.to_f / total_goals * 100).round
  end
  
  def calculate_investment_return
    total_initial = current_user.investments.sum(:initial_amount)
    return { value: 0, percentage: 0 } if total_initial <= 0
    
    total_current = current_user.investments.sum(:current_value)
    return_value = total_current - total_initial
    return_percentage = ((return_value / total_initial) * 100).round(2)
    
    { value: return_value, percentage: return_percentage }
  end
  
  def calculate_portfolio_allocation
    grouped_investments = current_user.investments.active.group(:investment_type).sum(:current_value)
    total = grouped_investments.values.sum
    return {} if total <= 0
    
    allocation = {}
    grouped_investments.each do |type, value|
      percentage = ((value / total) * 100).round(1)
      allocation[type] = { total: value, percentage: percentage }
    end
    
    allocation
  end
  
  def calculate_monthly_spending_trend
    # Get the last 6 months of spending data
    end_date = Date.current.end_of_month
    start_date = (end_date - 5.months).beginning_of_month
    
    # Initialize result structure
    result = { labels: [], values: [] }
    
    # Calculate spending for each month in the range
    current_month = start_date
    while current_month <= end_date
      month_end = current_month.end_of_month
      month_label = current_month.strftime('%b %Y')
      
      # Calculate total spending for this month
      monthly_spending = current_user.payments
                                    .where(created_at: current_month..month_end)
                                    .sum(:amount)
      
      result[:labels] << month_label
      result[:values] << monthly_spending.to_f
      
      current_month = current_month.next_month.beginning_of_month
    end
    
    result
  end
  
  def generate_insights
    insights = []
    
    # Spending pattern insights
    if @total_spending > 0
      highest_category = @spending_by_category.max_by { |_, amount| amount }
      if highest_category
        category_name, amount = highest_category
        percentage = ((amount / @total_spending) * 100).round
        if percentage > HIGH_CATEGORY_SPENDING_THRESHOLD
          insights << "Your #{category_name} spending (#{percentage}%) is significantly higher than other categories."
        end
      end
    end
    
    # Debt insights
    if @debt_analysis[:is_over_indebted]
      insights << "Consider debt consolidation to reduce your debt-to-income ratio."
    end
    
    # Savings insights
    if @projected_balance < 0
      insights << "You're projected to overspend this month. Consider reducing non-essential expenses."
    end
    
    # Goal-related insights
    if @active_goals.any?
      behind_goals = @active_goals.select { |goal| goal.progress_percentage < 25 && goal.days_remaining && goal.days_remaining < 30 }
      if behind_goals.any?
        insights << "You're behind on #{behind_goals.count} financial goals that are due soon."
      end
    end
    
    insights
  end
  
  def parse_date_param(date_string)
    return nil if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError, TypeError
    nil
  end
end
