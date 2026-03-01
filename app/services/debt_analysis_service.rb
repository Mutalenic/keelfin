class DebtAnalysisService
  def initialize(user)
    @user = user
    @active_debts = user.debts.active.to_a # single query; all methods compute in memory
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
    @active_debts.sum(&:principal_amount)
  end

  def monthly_payments
    @active_debts.sum { |d| d.monthly_payment || 0 }
  end

  def debt_to_income_ratio
    @user.debt_to_income_ratio
  end

  def over_indebted?
    debt_to_income_ratio > User::DEBT_TO_INCOME_THRESHOLD
  end
  alias is_over_indebted? over_indebted?

  def recommendations
    return [] unless is_over_indebted?

    [
      "Your debt payments (#{debt_to_income_ratio}%) exceed the safe 40% threshold.",
      'Consider debt consolidation to reduce interest rates.',
      'Prioritize high-interest debts first (avalanche method).',
      'Seek financial counseling if stress is overwhelming.'
    ]
  end

  def payoff_strategies
    {
      avalanche: @active_debts
        .select(&:interest_rate)
        .sort_by { |d| -d.interest_rate }
        .map { |d| [d.lender_name, d.interest_rate] },
      snowball: @active_debts
        .sort_by(&:principal_amount)
        .map { |d| [d.lender_name, d.principal_amount] }
    }
  end
end
