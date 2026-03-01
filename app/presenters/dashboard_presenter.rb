class DashboardPresenter
  HIGH_CATEGORY_SPENDING_THRESHOLD = 40
  UPCOMING_RECURRING_DAYS          = 7
  DASHBOARD_GOALS_LIMIT            = 3
  DASHBOARD_INVEST_LIMIT           = 3
  RECENT_PAYMENTS_LIMIT            = 10
  MONTHLY_TREND_MONTHS             = 6

  attr_reader :user, :start_date, :end_date

  def initialize(user, start_date:, end_date:)
    @user       = user
    @start_date = start_date
    @end_date   = end_date
  end

  def date_range
    @date_range ||= start_date..end_date
  end

  # --- Spending ---

  def total_spending
    @total_spending ||= user.total_spending(date_range)
  end

  def spending_by_category
    @spending_by_category ||= user.spending_by_category(date_range)
  end

  def burn_rate
    @burn_rate ||= user.burn_rate
  end

  def projected_balance
    @projected_balance ||= user.projected_month_end_balance
  end

  # --- External services (memoized so each is called once) ---

  def debt_analysis
    @debt_analysis ||= DebtAnalysisService.new(user).analyze
  end

  def bnnb_comparison
    @bnnb_comparison ||= BnnbComparisonService.new(user).compare
  end

  # --- Goals ---

  def active_goals
    @active_goals ||= user.financial_goals.in_progress.order(target_date: :asc).limit(DASHBOARD_GOALS_LIMIT)
  end

  def goals_progress
    @goals_progress ||= begin
      total = user.financial_goals.count
      return 0 if total.zero?

      completed = user.financial_goals.completed.count
      (completed.to_f / total * 100).round
    end
  end

  # --- Investments ---

  def investments
    @investments ||= user.investments.active.order(current_value: :desc).limit(DASHBOARD_INVEST_LIMIT)
  end

  def total_invested
    @total_invested ||= investments.sum(:current_value)
  end

  def investment_return
    @investment_return ||= begin
      total_initial = user.investments.sum(:initial_amount)
      return { value: 0, percentage: 0 } if total_initial <= 0

      total_current = user.investments.sum(:current_value)
      return_value  = total_current - total_initial
      { value: return_value, percentage: ((return_value / total_initial) * 100).round(2) }
    end
  end

  def portfolio_allocation
    @portfolio_allocation ||= begin
      grouped = user.investments.active.group(:investment_type).sum(:current_value)
      total   = grouped.values.sum
      return {} if total <= 0

      grouped.transform_values do |value|
        { total: value, percentage: ((value / total) * 100).round(1) }
      end
    end
  end

  # --- Recurring transactions ---

  def upcoming_recurring
    @upcoming_recurring ||= user.recurring_transactions.active
                                .where('next_occurrence <= ?', UPCOMING_RECURRING_DAYS.days.from_now)
                                .order(next_occurrence: :asc)
                                .limit(DASHBOARD_GOALS_LIMIT)
  end

  # --- Recent activity ---

  def recent_payments
    @recent_payments ||= user.payments.includes(:category).recent.limit(RECENT_PAYMENTS_LIMIT)
  end

  def latest_economic_data
    @latest_economic_data ||= EconomicIndicator.latest
  end

  def monthly_spending_trend
    @monthly_spending_trend ||= calculate_monthly_spending_trend
  end

  # --- Insights ---

  def financial_insights
    @financial_insights ||= generate_insights
  end

  private

  def calculate_monthly_spending_trend
    trend_end   = Date.current.end_of_month
    trend_start = (trend_end - (MONTHLY_TREND_MONTHS - 1).months).beginning_of_month

    monthly_totals = user.payments
                         .where(created_at: trend_start..trend_end)
                         .group("DATE_TRUNC('month', created_at)")
                         .sum(:amount)

    result        = { labels: [], values: [] }
    current_month = trend_start

    while current_month <= trend_end
      result[:labels] << current_month.strftime('%b %Y')
      result[:values] << (monthly_totals[current_month.beginning_of_month] || 0).to_f
      current_month = current_month.next_month.beginning_of_month
    end

    result
  end

  def generate_insights
    insights = []

    if total_spending > 0
      highest = spending_by_category.max_by { |_, amount| amount }
      if highest
        name, amount = highest
        pct = ((amount / total_spending) * 100).round
        if pct > HIGH_CATEGORY_SPENDING_THRESHOLD
          insights << "Your #{name} spending (#{pct}%) is significantly higher than other categories."
        end
      end
    end

    if debt_analysis[:is_over_indebted]
      insights << 'Consider debt consolidation to reduce your debt-to-income ratio.'
    end

    if projected_balance < 0
      insights << "You're projected to overspend this month. Consider reducing non-essential expenses."
    end

    if active_goals.any?
      behind = active_goals.select { |g| g.progress_percentage < 25 && g.days_remaining && g.days_remaining < 30 }
      insights << "You're behind on #{behind.count} financial goals that are due soon." if behind.any?
    end

    insights
  end
end
