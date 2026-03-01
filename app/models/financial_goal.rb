class FinancialGoal < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true

  validates :name, presence: true, length: { maximum: 100 }
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :start_date, presence: true
  validates :target_date, presence: true
  validates :goal_type, presence: true, inclusion: { in: %w[saving debt_payment investment expense_reduction] }

  validate :target_date_after_start_date

  scope :active, -> { where(target_date: Date.current..) }
  scope :completed, -> { where(completed: true) }
  scope :in_progress, -> { active.where(completed: false) }
  scope :overdue, -> { where(completed: false).where(target_date: ...Date.current) }

  def progress_percentage
    return 0 if current_amount.nil? || current_amount <= 0
    return 100 if current_amount >= target_amount

    ((current_amount.to_f / target_amount) * 100).round(1)
  end

  def days_remaining
    return 0 if completed? || target_date < Date.current

    (target_date - Date.current).to_i
  end

  def daily_target
    return 0 if completed? || days_remaining <= 0

    remaining_amount = target_amount - (current_amount || 0)
    (remaining_amount / days_remaining).round(2)
  end

  def check_completion
    return unless current_amount && current_amount >= target_amount

    update(completed: true, completion_date: Date.current)
  end

  private

  def target_date_after_start_date
    return if start_date.nil? || target_date.nil?

    return unless target_date <= start_date

    errors.add(:target_date, 'must be after the start date')
  end
end
