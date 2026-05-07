class IncomeSource < ApplicationRecord
  belongs_to :user

  FREQUENCIES = %w[weekly biweekly monthly quarterly annually].freeze

  validates :name, presence: true, length: { maximum: 100 }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :frequency, presence: true, inclusion: { in: FREQUENCIES }

  scope :active, -> { where(active: true) }
  scope :by_frequency, ->(f) { where(frequency: f) }

  def monthly_equivalent
    case frequency
    when 'weekly' then amount * 4.33
    when 'biweekly' then amount * 2.17
    when 'monthly' then amount
    when 'quarterly' then amount / 3.0
    when 'annually' then amount / 12.0
    else amount.to_f
    end
  end

  def frequency_label
    case frequency
    when 'weekly' then 'Weekly'
    when 'biweekly' then 'Bi-weekly'
    when 'monthly' then 'Monthly'
    when 'quarterly' then 'Quarterly'
    when 'annually' then 'Annually'
    else frequency.humanize
    end
  end
end
