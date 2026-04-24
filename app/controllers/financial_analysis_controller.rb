class FinancialAnalysisController < ApplicationController
  def index
    @months = (0..5).map { |i| Date.current - i.months }.reverse

    spending_by_month = current_user.payments
      .where(created_at: @months.first.beginning_of_month..Date.current.end_of_month)
      .group_by { |p| p.created_at.beginning_of_month }

    @monthly_data = @months.map do |m|
      start = m.beginning_of_month
      payments = spending_by_month[start] || []
      {
        month: m,
        spending: payments.sum(&:amount),
        transactions: payments.size
      }
    end

    @total_6m_spending = @monthly_data.sum { |d| d[:spending] }
    @avg_monthly_spending = @monthly_data.size > 0 ? (@total_6m_spending / @monthly_data.size) : 0

    month_start = Date.current.beginning_of_month
    month_end = Date.current.end_of_month

    @this_month_spending = current_user.payments
      .where(created_at: month_start..month_end)
      .sum(:amount)

    @top_categories = current_user.categories
      .joins(:payments)
      .where(payments: { created_at: month_start..month_end })
      .group('categories.id', 'categories.name')
      .order('SUM(payments.amount) DESC')
      .limit(8)
      .sum('payments.amount')

    @budget_performance = current_user.budgets.includes(:category).map do |b|
      spent = current_user.payments
        .where(category: b.category, created_at: month_start..month_end)
        .sum(:amount)
      pct = b.monthly_limit > 0 ? (spent.to_f / b.monthly_limit * 100).round(1) : 0
      { name: b.category.name, spent: spent, limit: b.monthly_limit, pct: pct }
    end.sort_by { |b| -b[:pct] }

    @income = current_user.total_monthly_income
    @savings_rate = @income > 0 ? [(((@income - @this_month_spending) / @income) * 100).round(1), 0].max : 0

    @debt_analysis = DebtAnalysisService.new(current_user).analyze
    @active_goals = current_user.financial_goals.where(status: 'active')
  end
end
