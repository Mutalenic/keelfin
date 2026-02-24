class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @total_spending = current_user.total_spending
    @spending_by_category = current_user.spending_by_category
    @burn_rate = current_user.burn_rate
    @projected_balance = current_user.projected_month_end_balance
    @debt_analysis = DebtAnalysisService.new(current_user).analyze
    @bnnb_comparison = BnnbComparisonService.new(current_user).compare
    @recent_payments = current_user.payments.recent.limit(10)
    @latest_economic_data = EconomicIndicator.latest
  end
end
