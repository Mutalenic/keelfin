class InvestmentTransaction < ApplicationRecord
  belongs_to :investment
  belongs_to :user

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_date, presence: true
  validates :transaction_type, presence: true, inclusion: { in: %w[contribution withdrawal dividend interest fee] }

  scope :contributions, -> { where(transaction_type: 'contribution') }
  scope :withdrawals, -> { where(transaction_type: 'withdrawal') }
  scope :income, -> { where(transaction_type: %w[dividend interest]) }
  scope :fees, -> { where(transaction_type: 'fee') }
  scope :recent, -> { order(transaction_date: :desc) }

  before_save :update_investment_value

  def transaction_type_text
    case transaction_type
    when 'contribution' then 'Contribution'
    when 'withdrawal' then 'Withdrawal'
    when 'dividend' then 'Dividend'
    when 'interest' then 'Interest'
    when 'fee' then 'Fee'
    else transaction_type.titleize
    end
  end

  private

  def update_investment_value
    investment = self.investment
    current_value = investment.current_value

    new_value = case transaction_type
                when 'contribution', 'dividend', 'interest'
                  current_value + amount
                when 'withdrawal', 'fee'
                  current_value - amount
                else
                  current_value
                end

    # Ensure value doesn't go below zero
    new_value = [new_value, 0].max

    # Update the investment's current value
    investment.update(current_value: new_value)
  end
end
