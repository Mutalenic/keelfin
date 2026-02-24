class Investment < ApplicationRecord
  belongs_to :user
  has_many :investment_transactions, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 100 }
  validates :investment_type, presence: true
  validates :initial_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :current_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(investment_type: type) }
  
  def total_contributions
    initial_amount + investment_transactions.where(transaction_type: 'contribution').sum(:amount)
  end
  
  def total_withdrawals
    investment_transactions.where(transaction_type: 'withdrawal').sum(:amount)
  end
  
  def net_contributions
    total_contributions - total_withdrawals
  end
  
  def total_return
    current_value - net_contributions
  end
  
  def return_percentage
    return 0 if net_contributions <= 0
    ((total_return / net_contributions) * 100).round(2)
  end
  
  def annualized_return
    return 0 if created_at.nil? || net_contributions <= 0
    
    # Calculate years since investment creation
    years = (Date.current - created_at.to_date).to_f / 365
    return 0 if years < 0.1 # Avoid division by very small numbers
    
    # Calculate annualized return using CAGR formula
    cagr = ((current_value / net_contributions) ** (1 / years) - 1) * 100
    cagr.round(2)
  end
  
  def risk_level_text
    case risk_level
    when 1 then "Very Low"
    when 2 then "Low"
    when 3 then "Moderate"
    when 4 then "High"
    when 5 then "Very High"
    else "Not Specified"
    end
  end
  
  def investment_type_text
    case investment_type
    when 'stocks' then 'Stocks'
    when 'bonds' then 'Bonds'
    when 'mutual_funds' then 'Mutual Funds'
    when 'etfs' then 'ETFs'
    when 'real_estate' then 'Real Estate'
    when 'crypto' then 'Cryptocurrency'
    when 'savings' then 'Savings Account'
    when 'fixed_deposit' then 'Fixed Deposit'
    when 'pension' then 'Pension Fund'
    when 'other' then 'Other'
    else investment_type.titleize
    end
  end
  
  def update_current_value(new_value)
    # Create a value history entry
    value_history = self.value_history || []
    value_history << { date: Date.current.to_s, value: new_value.to_f }
    
    # Update the current value and value history
    update(
      current_value: new_value,
      value_history: value_history,
      last_updated: Date.current
    )
  end
  
  def performance_trend
    return 'neutral' if value_history.nil? || value_history.length < 2
    
    # Get the last two recorded values
    last_values = value_history.sort_by { |entry| Date.parse(entry['date']) }.last(2)
    return 'neutral' if last_values.length < 2
    
    if last_values[1]['value'] > last_values[0]['value']
      'positive'
    elsif last_values[1]['value'] < last_values[0]['value']
      'negative'
    else
      'neutral'
    end
  end
end
