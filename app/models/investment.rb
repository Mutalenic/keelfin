class Investment < ApplicationRecord
  belongs_to :user
  has_many :investment_transactions, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 100 }
  validates :investment_type, presence: true
  validates :initial_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :current_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(investment_type: type) }
  
  # One grouped query; all per-type sums are memoized so subsequent calls are free.
  def transaction_sums_by_type
    @transaction_sums_by_type ||= investment_transactions
                                    .group(:transaction_type)
                                    .sum(:amount)
                                    .transform_values { |v| v || 0 }
  end

  def total_contributions
    initial_amount + (transaction_sums_by_type['contribution'] || 0)
  end

  def total_withdrawals
    transaction_sums_by_type['withdrawal'] || 0
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
    return 0 if created_at.nil?
    return 0 if net_contributions <= 0 || net_contributions.zero?
    
    # Calculate years since investment creation
    years = (Date.current - created_at.to_date).to_f / 365
    return 0 if years < 0.1 # Avoid division by very small numbers
    
    # Calculate annualized return using CAGR formula
    # Add safety check for current_value
    return 0 if current_value <= 0
    
    cagr = ((current_value.to_f / net_contributions.to_f) ** (1.0 / years) - 1) * 100
    cagr.round(2)
  rescue Math::DomainError, ZeroDivisionError
    0
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
    value_history << { 'date' => Date.current.to_s, 'value' => new_value.to_f }
    
    # Implement retention policy: keep only last 365 days
    cutoff_date = 365.days.ago.to_date
    value_history = value_history.select do |entry|
      begin
        Date.parse(entry['date']) >= cutoff_date
      rescue ArgumentError
        false # Remove entries with invalid dates
      end
    end
    
    # Update the current value and value history
    update(
      current_value: new_value,
      value_history: value_history,
      last_updated: Date.current
    )
  end
  
  def performance_trend
    return 'neutral' if value_history.nil? || value_history.length < 2
    
    # Get the last two recorded values with safe date parsing
    begin
      last_values = value_history.sort_by { |entry| Date.parse(entry['date']) }.last(2)
    rescue ArgumentError, TypeError
      return 'neutral'
    end
    
    return 'neutral' if last_values.length < 2
    
    if last_values[1]['value'].to_f > last_values[0]['value'].to_f
      'positive'
    elsif last_values[1]['value'].to_f < last_values[0]['value'].to_f
      'negative'
    else
      'neutral'
    end
  end
end
