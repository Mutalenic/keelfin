class Debt < ApplicationRecord
  belongs_to :user
  
  validates :lender_name, presence: true
  validates :principal_amount, presence: true, numericality: { greater_than: 0 }
  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :monthly_payment, numericality: { greater_than: 0 }, allow_nil: true
  validates :status, inclusion: { in: %w[active paid_off], message: "%{value} is not a valid status" }, allow_nil: true
  
  scope :active, -> { where(status: 'active') }
  scope :paid_off, -> { where(status: 'paid_off') }
  
  def remaining_balance
    # TODO: Implement actual remaining balance calculation based on payments made
    # For now, return principal amount as placeholder
    principal_amount
  end
  
  def total_interest_cost
    return 0 unless monthly_payment && end_date && start_date
    return 0 if end_date < start_date
    
    months = ((end_date.year - start_date.year) * 12 + end_date.month - start_date.month)
    return 0 if months <= 0
    
    total_paid = monthly_payment * months
    interest = total_paid - principal_amount
    [interest, 0].max # Ensure non-negative
  end
  
  def debt_to_income_ratio
    return 0 unless user.monthly_income && user.monthly_income > 0 && monthly_payment
    (monthly_payment.to_f / user.monthly_income * 100).round(2)
  end
end
