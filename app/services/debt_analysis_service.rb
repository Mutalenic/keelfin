class DebtAnalysisService
  def initialize(user)
    @user = user
  end
  
  def analyze
    {
      total_debt: total_debt,
      monthly_payments: monthly_payments,
      debt_to_income: debt_to_income_ratio,
      is_over_indebted: is_over_indebted?,
      recommendations: recommendations,
      payoff_strategies: payoff_strategies
    }
  end
  
  private
  
  def total_debt
    @user.debts.active.sum(:principal_amount)
  end
  
  def monthly_payments
    @user.debts.active.sum(:monthly_payment)
  end
  
  def debt_to_income_ratio
    @user.debt_to_income_ratio
  end
  
  def is_over_indebted?
    debt_to_income_ratio > 40
  end
  
  def recommendations
    return [] unless is_over_indebted?
    
    [
      "Your debt payments (#{debt_to_income_ratio}%) exceed the safe 40% threshold.",
      "Consider debt consolidation to reduce interest rates.",
      "Prioritize high-interest debts first (avalanche method).",
      "Seek financial counseling if stress is overwhelming."
    ]
  end
  
  def payoff_strategies
    active_debts = @user.debts.active
    
    {
      avalanche: active_debts.order(interest_rate: :desc).pluck(:lender_name, :interest_rate),
      snowball: active_debts.order(principal_amount: :asc).pluck(:lender_name, :principal_amount)
    }
  end
end
