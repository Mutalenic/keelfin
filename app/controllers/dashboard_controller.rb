class DashboardController < ApplicationController
  def index
    start_date = parse_date_param(params[:start_date]) || Date.current.beginning_of_month
    end_date = parse_date_param(params[:end_date]) || Date.current.end_of_month

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
  end
end
