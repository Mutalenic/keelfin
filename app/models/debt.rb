class Debt < ApplicationRecord
  belongs_to :user
  has_many :debt_payments, dependent: :destroy

  validates :lender_name, presence: true
  validates :principal_amount, presence: true, numericality: { greater_than: 0 }
  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :monthly_payment, numericality: { greater_than: 0 }, allow_nil: true
  validates :status, inclusion: { in: %w[active paid_off], message: '%<value>s is not a valid status' }, allow_nil: true

  scope :active, -> { where(status: 'active') }
  scope :paid_off, -> { where(status: 'paid_off') }

  def remaining_balance
    [principal_amount.to_f - total_paid_amount, 0].max
  end

  def total_paid_amount
    debt_payments.sum(:amount).to_f
  end

  def payment_count
    debt_payments.count
  end

  def payoff_percentage
    return 100 if status == 'paid_off'
    return 0 if principal_amount.zero?

    [(total_paid_amount / principal_amount.to_f * 100).round(1), 100].min
  end

  def total_interest_cost
    return 0 unless monthly_payment && end_date && start_date
    return 0 if end_date < start_date

    # Calculate months more accurately
    months = (((end_date.year * 12) + end_date.month) - ((start_date.year * 12) + start_date.month))
    return 0 if months <= 0

    total_paid = monthly_payment.to_f * months
    interest = total_paid - principal_amount.to_f
    [interest, 0].max # Ensure non-negative
  end

  def debt_to_income_ratio
    return 0 unless user.monthly_income&.positive? && monthly_payment

    (monthly_payment.to_f / user.monthly_income * 100).round(2)
  end
end
