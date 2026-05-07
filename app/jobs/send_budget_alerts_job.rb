class SendBudgetAlertsJob < ApplicationJob
  queue_as :default

  def perform
    User.joins(:budgets).distinct.each do |user|
      budget_data = build_budget_data(user)
      next if budget_data.empty?

      BudgetAlertMailer.near_limit(user, budget_data).deliver_later
      Rails.logger.info "Budget alert sent to user #{user.id} (#{budget_data.size} budget(s) flagged)"
    rescue StandardError => e
      Rails.logger.error "SendBudgetAlertsJob failed for user #{user.id}: #{e.message}"
    end
  end

  private

  def build_budget_data(user)
    month_start = Date.current.beginning_of_month
    month_end = month_start.end_of_month

    spending = user.payments
      .where(created_at: month_start..month_end)
      .group(:category_id)
      .sum(:amount)

    user.budgets.includes(:category).filter_map do |budget|
      spent = spending[budget.category_id] || 0
      pct = budget.monthly_limit.positive? ? (spent.to_f / budget.monthly_limit * 100).round(2) : 0
      next if pct < 80

      {
        name: budget.category.name,
        spent: spent,
        limit: budget.monthly_limit,
        pct: pct,
        overspent_by: [spent - budget.monthly_limit, 0].max
      }
    end
  end
end
