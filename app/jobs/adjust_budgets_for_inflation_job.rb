class AdjustBudgetsForInflationJob < ApplicationJob
  queue_as :default
  
  def perform
    latest_inflation = EconomicIndicator.latest_inflation
    return unless latest_inflation
    
    # Convert annual inflation to monthly
    monthly_inflation = latest_inflation / 12
    
    Budget.where(inflation_adjusted: true).find_each do |budget|
      budget.adjust_for_inflation!(monthly_inflation)
    end
    
    count = Budget.where(inflation_adjusted: true).count
    Rails.logger.info "Adjusted #{count} budgets for inflation (#{monthly_inflation}% monthly)"
  rescue StandardError => e
    Rails.logger.error "Failed to adjust budgets for inflation: #{e.message}"
  end
end
