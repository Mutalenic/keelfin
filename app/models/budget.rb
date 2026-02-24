class Budget < ApplicationRecord
  belongs_to :user
  belongs_to :category
  
  validates :monthly_limit, presence: true, numericality: { greater_than: 0 }
  validates :category_id, uniqueness: { scope: [:user_id, :start_date], message: "already has a budget for this period" }
  validate :category_belongs_to_user
  validate :end_date_after_start_date
  
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

  private

  def category_belongs_to_user
    return unless category
    errors.add(:category, "must belong to you") if category.user_id != user_id
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
end
