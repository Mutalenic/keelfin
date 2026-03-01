class RecurringTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :frequency, presence: true, inclusion: { in: %w[daily weekly biweekly monthly quarterly yearly] }
  validates :start_date, presence: true

  scope :active, -> { where(active: true) }
  scope :due_today, -> { active.where(next_occurrence: ..Date.current) }

  before_create :set_next_occurrence

  def process_transaction
    return unless active? && next_occurrence <= Date.current

    # Use a transaction with lock to prevent race conditions
    transaction do
      # Lock this record for update
      lock!

      # Double-check conditions after acquiring lock
      return unless active? && next_occurrence <= Date.current

      # Create the actual payment
      payment = Payment.create!(
        name: name,
        amount: amount,
        user: user,
        category: category,
        payment_method: payment_method,
        is_essential: is_essential,
        notes: "Auto-generated from recurring transaction: #{name}"
      )

      # Update the next occurrence date
      update_next_occurrence

      # Return the created payment
      payment
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::StaleObjectError
    # Handle race condition gracefully
    Rails.logger.warn "Race condition detected for recurring transaction #{id}"
    nil
  end

  def update_next_occurrence
    self.last_occurrence = Date.current
    self.next_occurrence = calculate_next_occurrence
    save!
  end

  def calculate_next_occurrence
    return nil unless active?

    base_date = next_occurrence || start_date

    case frequency
    when 'daily'
      base_date + 1.day
    when 'weekly'
      base_date + 1.week
    when 'biweekly'
      base_date + 2.weeks
    when 'monthly'
      base_date + 1.month
    when 'quarterly'
      base_date + 3.months
    when 'yearly'
      base_date + 1.year
    end
  end

  def frequency_in_days
    case frequency
    when 'daily' then 1
    when 'weekly' then 7
    when 'biweekly' then 14
    when 'quarterly' then 90
    when 'yearly' then 365
    else 30 # monthly, nil, or unknown
    end
  end

  def estimated_monthly_impact
    case frequency
    when 'daily'
      amount * 30
    when 'weekly'
      amount * 4.33
    when 'biweekly'
      amount * 2.17
    when 'monthly'
      amount
    when 'quarterly'
      amount / 3
    when 'yearly'
      amount / 12
    else
      0
    end
  end

  def human_readable_frequency
    case frequency
    when 'daily' then 'Every day'
    when 'weekly' then 'Every week'
    when 'biweekly' then 'Every two weeks'
    when 'monthly' then 'Every month'
    when 'quarterly' then 'Every 3 months'
    when 'yearly' then 'Every year'
    else frequency.humanize
    end
  end

  private

  def set_next_occurrence
    self.next_occurrence ||= start_date
  end
end
