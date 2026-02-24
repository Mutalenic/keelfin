class Budget < ApplicationRecord
  belongs_to :user
  belongs_to :category
  
  validates :monthly_limit, presence: true, numericality: { greater_than: 0 }
  
  def current_spending(month = Date.current.beginning_of_month)
    month_start = month.beginning_of_month
    month_end = month_start.end_of_month
    
    category.payments
      .where(user: user)
      .where('created_at >= ? AND created_at <= ?', month_start, month_end)
      .sum(:amount)
  end
  
  def remaining_budget(month = Date.current.beginning_of_month)
    monthly_limit - current_spending(month)
  end
  
  def percentage_used(month = Date.current.beginning_of_month)
    return 0 if monthly_limit.zero?
    (current_spending(month) / monthly_limit * 100).round(2)
  end
  
  def is_overspent?(month = Date.current.beginning_of_month)
    current_spending(month) > monthly_limit
  end
  
  def adjust_for_inflation!(inflation_rate)
    return unless inflation_adjusted
    return if inflation_rate.nil? || inflation_rate.zero?
    
    self.monthly_limit *= (1 + inflation_rate / 100)
    save
  end
end
