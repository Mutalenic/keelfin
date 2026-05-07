class AnnualOverviewController < ApplicationController
  def index
    @year = params[:year]&.to_i || Date.current.year
    @months = (1..12).map { |m| Date.new(@year, m, 1) }

    @income_sources = current_user.income_sources.active
    @categories_with_budgets = current_user.categories
      .includes(:budgets, :payments)
      .order(:name)

    @monthly_data = build_monthly_data
    @annual_totals = build_annual_totals
  end

  private

  def build_monthly_data
    @months.map do |month|
      period = month.all_month

      income = if @income_sources.any?
                 @income_sources.sum(&:monthly_equivalent)
               else
                 current_user.monthly_income.to_f
               end

      spending = current_user.payments.where(created_at: period).sum(:amount).to_f

      category_spend = current_user.payments
        .where(created_at: period)
        .joins(:category)
        .group('categories.id', 'categories.name')
        .sum(:amount)

      budget_limits = current_user.budgets
        .where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', month.end_of_month, month.beginning_of_month)
        .group(:category_id)
        .sum(:monthly_limit)

      {
        month: month,
        income: income,
        spending: spending,
        balance: income - spending,
        category_spend: category_spend,
        budget_limits: budget_limits,
        is_past: month < Date.current.beginning_of_month,
        is_current: month.month == Date.current.month && month.year == Date.current.year
      }
    end
  end

  def build_annual_totals
    total_income = @monthly_data.sum { |d| d[:income] }
    total_spending = @monthly_data.select { |d| d[:is_past] || d[:is_current] }.sum { |d| d[:spending] }

    {
      income: total_income,
      spending: total_spending,
      balance: total_income - total_spending
    }
  end
end
