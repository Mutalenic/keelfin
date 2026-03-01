class Budget < ApplicationRecord
  belongs_to :user
  belongs_to :category

  attr_writer :preloaded_spending

  validates :monthly_limit, presence: true, numericality: { greater_than: 0 }
  validate :category_belongs_to_user
  validate :end_date_after_start_date
  validate :unique_category_budget

  def current_spending(month = Date.current.beginning_of_month)
    return @preloaded_spending if defined?(@preloaded_spending) && month == Date.current.beginning_of_month

    month_start = month.beginning_of_month
    month_end = month_start.end_of_month

    category.payments
      .where(user: user)
      .where(created_at: month_start..month_end)
      .sum(:amount)
  end

  def remaining_budget(month = Date.current.beginning_of_month)
    monthly_limit - current_spending(month)
  end

  def percentage_used(month = Date.current.beginning_of_month)
    return 0 if monthly_limit.zero?

    (current_spending(month).to_f / monthly_limit * 100).round(2)
  end

  def is_overspent?(month = Date.current.beginning_of_month)
    current_spending(month) > monthly_limit
  end

  def adjust_for_inflation!(inflation_rate)
    return false unless inflation_adjusted
    return false if inflation_rate.nil? || inflation_rate.zero?

    new_limit = monthly_limit * (1 + (inflation_rate / 100.0))
    update!(monthly_limit: new_limit)
    true
  end

  private

  def category_belongs_to_user
    return unless category

    errors.add(:category, 'must belong to you') if category.user_id != user_id
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end

  def unique_category_budget
    return unless user_id && category_id

    # Build base query for same user and category
    existing = Budget.where(user_id: user_id, category_id: category_id)
    existing = existing.where.not(id: id) if persisted?

    # Check for overlapping date ranges using standard overlap logic:
    # Two ranges overlap if: (start1 <= end2) AND (end1 >= start2)
    if start_date.present?
      this_end = end_date || Date.new(9999, 12, 31) # Use far future date for NULL end_date

      # Check for overlaps: existing budget overlaps if its range intersects with this budget's range
      existing = existing.where(
        "(start_date <= ? AND (COALESCE(end_date, '9999-12-31') >= ?))",
        this_end, start_date
      )
    end

    errors.add(:category_id, 'already has a budget for this period') if existing.exists?
  end
end
