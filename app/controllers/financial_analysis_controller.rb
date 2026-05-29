class FinancialAnalysisController < ApplicationController
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def index
    @months = (0..5).map { |i| Date.current - i.months }.reverse

    raw_monthly = current_user.payments
      .where(created_at: @months.first.beginning_of_month..Date.current.end_of_month)
      .group(Arel.sql("DATE_TRUNC('month', created_at)::date"))
      .pluck(
        Arel.sql("DATE_TRUNC('month', created_at)::date"),
        Arel.sql('SUM(amount)'),
        Arel.sql('COUNT(*)')
      )
      .each_with_object({}) { |(m, s, c), h| h[m.to_date.beginning_of_month] = { spending: s.to_f, transactions: c } }

    @monthly_data = @months.map do |m|
      data = raw_monthly[m.beginning_of_month] || { spending: 0.0, transactions: 0 }
      { month: m, spending: data[:spending], transactions: data[:transactions] }
    end

    @total_6m_spending = @monthly_data.sum { |d| d[:spending] }
    @avg_monthly_spending = @monthly_data.size.positive? ? (@total_6m_spending / @monthly_data.size) : 0

    month_start = Date.current.beginning_of_month
    month_end = Date.current.end_of_month

    @this_month_spending = current_user.payments
      .where(created_at: month_start..month_end)
      .sum(:amount)

    @top_categories = current_user.categories
      .joins(:payments)
      .where(payments: { created_at: month_start..month_end })
      .group('categories.id', 'categories.name')
      .select('categories.name, SUM(payments.amount) AS total_amount')
      .order(Arel.sql('SUM(payments.amount) DESC'))
      .limit(8)
      .to_h { |c| [c.name, c.total_amount.to_f] }

    category_spending = current_user.payments
      .where(created_at: month_start..month_end)
      .group(:category_id)
      .sum(:amount)

    budget_rows = current_user.budgets.includes(:category).map do |b|
      spent = category_spending[b.category_id] || 0
      pct = b.monthly_limit.positive? ? (spent.to_f / b.monthly_limit * 100).round(1) : 0
      { name: b.category.name, spent: spent, limit: b.monthly_limit, pct: pct }
    end
    @budget_performance = budget_rows.sort_by { |b| -b[:pct] }

    @income = current_user.total_monthly_income
    @savings_rate = @income.positive? ? [(((@income - @this_month_spending) / @income) * 100).round(1), 0].max : 0

    @debt_analysis = DebtAnalysisService.new(current_user).analyze
    @active_goals = current_user.financial_goals.where(completed: false)
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
