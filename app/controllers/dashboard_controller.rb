class DashboardController < ApplicationController
  def index
    if params[:month].present?
      selected = Date.strptime(params[:month], '%Y-%m') rescue Date.current
      start_date = selected.beginning_of_month
      end_date = selected.end_of_month
    else
      start_date = parse_date_param(params[:start_date]) || Date.current.beginning_of_month
      end_date = parse_date_param(params[:end_date]) || Date.current.end_of_month
    end

    @presenter = DashboardPresenter.new(current_user, start_date: start_date, end_date: end_date)
    assign_presenter_variables
  end

  private

  def parse_date_param(date_string)
    return nil if date_string.blank?

    Date.parse(date_string)
  rescue ArgumentError, TypeError
    nil
  end

  def assign_presenter_variables
    @start_date = @presenter.start_date
    @end_date = @presenter.end_date
    @date_range = @presenter.date_range
    @total_spending = @presenter.total_spending
    @total_monthly_income = @presenter.total_monthly_income
    @actual_balance = @presenter.actual_balance
    @spending_by_category = @presenter.spending_by_category
    @burn_rate = @presenter.burn_rate
    @projected_balance = @presenter.projected_balance
    @debt_analysis = @presenter.debt_analysis
    @bnnb_comparison = @presenter.bnnb_comparison
    @active_goals = @presenter.active_goals
    @goals_progress = @presenter.goals_progress
    @investments = @presenter.investments
    @total_invested = @presenter.total_invested
    @investment_return = @presenter.investment_return
    @portfolio_allocation = @presenter.portfolio_allocation
    @upcoming_recurring = @presenter.upcoming_recurring
    @recent_payments = @presenter.recent_payments
    @latest_economic_data = @presenter.latest_economic_data
    @monthly_spending_trend = @presenter.monthly_spending_trend
    @financial_insights = @presenter.financial_insights
    @budget_alerts = build_budget_alerts
  end

  def build_budget_alerts
    budgets = current_user.budgets.includes(:category)
    month_start = @start_date.beginning_of_month
    month_end = month_start.end_of_month

    spending_by_category = current_user.payments
      .where(created_at: month_start..month_end)
      .group(:category_id)
      .sum(:amount)

    budgets.filter_map do |budget|
      spent = spending_by_category[budget.category_id] || 0
      pct = budget.monthly_limit > 0 ? (spent.to_f / budget.monthly_limit * 100).round(2) : 0
      next if pct < 80

      {
        name: budget.category.name,
        spent: spent,
        limit: budget.monthly_limit,
        pct: pct,
        overspent_by: [spent - budget.monthly_limit, 0].max
      }
    end.sort_by { |b| -b[:pct] }
  end
end
