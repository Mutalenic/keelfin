class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  DEBT_TO_INCOME_THRESHOLD = 40

  has_many :categories, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :debts, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :financial_goals, dependent: :destroy
  has_many :recurring_transactions, dependent: :destroy
  has_many :investments, dependent: :destroy
  has_many :investment_transactions, through: :investments
  has_one :subscription, dependent: :destroy

  validates :name, presence: true, length: { maximum: 50, minimum: 2 }
  validates :monthly_income, numericality: { greater_than: 0 }, allow_nil: true
  validates :phone_number, format: { with: /\A\+?260\d{9}\z/ }, allow_nil: true

  def admin?
    role == 'admin'
  end

  def total_debt_payments
    debts.active.where.not(monthly_payment: nil).sum(:monthly_payment)
  end

  def debt_to_income_ratio
    return 0 unless monthly_income&.positive?

    (total_debt_payments / monthly_income * 100).round(2)
  end

  def over_indebted?
    debt_to_income_ratio > DEBT_TO_INCOME_THRESHOLD
  end

  alias is_over_indebted? over_indebted?

  def total_spending(period = Date.current.all_month)
    payments.where(created_at: period).sum(:amount)
  end

  def spending_by_category(period = Date.current.all_month)
    payments.where(created_at: period)
      .joins(:category)
      .group('categories.name')
      .sum(:amount)
  end

  def burn_rate(days = 7)
    start_date = days.days.ago
    total = total_spending(start_date..Date.current)
    return 0 if days.zero?

    total.to_f / days
  end

  def projected_month_end_balance
    return 0 unless monthly_income

    days_in_month = Date.current.end_of_month.day
    days_elapsed = Date.current.day
    return 0 if days_elapsed.zero?

    daily_burn = burn_rate(days_elapsed)
    monthly_income.to_f - (daily_burn * days_in_month)
  end

  # Subscription and premium features
  def subscription?
    subscription.present?
  end

  alias has_subscription? subscription?

  def active_subscription?
    has_subscription? && subscription.active?
  end

  def premium?
    active_subscription? && subscription.plan_name == 'premium'
  end

  def standard?
    active_subscription? && subscription.plan_name == 'standard'
  end

  def free_plan?
    !has_subscription? || subscription.plan_name == 'free'
  end

  def can_access_feature?(feature)
    return true if admin?
    return false unless has_subscription?

    subscription.can_access_feature?(feature)
  end

  def max_categories
    return Float::INFINITY if admin?
    return Subscription::PLANS[:free][:features][:max_categories] unless has_subscription?

    max = subscription.features&.[]('max_categories') || Subscription::PLANS[:free][:features][:max_categories]
    max == -1 ? Float::INFINITY : max
  end

  def max_budgets
    return Float::INFINITY if admin?
    return Subscription::PLANS[:free][:features][:max_budgets] unless has_subscription?

    max = subscription.features&.[]('max_budgets') || Subscription::PLANS[:free][:features][:max_budgets]
    max == -1 ? Float::INFINITY : max
  end

  def ensure_subscription
    return subscription if has_subscription?

    Subscription.create_free_subscription(self)
  end
end
