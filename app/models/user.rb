class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_many :categories, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :debts, dependent: :destroy
  has_many :budgets, dependent: :destroy

  validates :name, presence: true, length: { maximum: 50, minimum: 2 }
  validates :monthly_income, numericality: { greater_than: 0 }, allow_nil: true
  validates :phone_number, format: { with: /\A\+?260\d{9}\z/ }, allow_nil: true

  def admin?
    role == 'admin'
  end
  
  def total_debt_payments
    debts.active.sum(:monthly_payment)
  end
  
  def debt_to_income_ratio
    return 0 unless monthly_income && monthly_income > 0
    (total_debt_payments / monthly_income * 100).round(2)
  end
  
  def is_over_indebted?
    debt_to_income_ratio > 40
  end
  
  def total_spending(period = Date.current.beginning_of_month..Date.current.end_of_month)
    payments.where(created_at: period).sum(:amount)
  end
  
  def spending_by_category(period = Date.current.beginning_of_month..Date.current.end_of_month)
    payments.where(created_at: period)
      .joins(:category)
      .group('categories.name')
      .sum(:amount)
  end
  
  def burn_rate(days = 7)
    start_date = days.days.ago
    total = total_spending(start_date..Date.current)
    return 0 if days.zero?
    total / days
  end
  
  def projected_month_end_balance
    days_in_month = Date.current.end_of_month.day
    days_elapsed = Date.current.day
    return 0 if days_elapsed.zero?
    
    daily_burn = burn_rate(days_elapsed)
    monthly_income.to_f - (daily_burn * days_in_month)
  end
end
