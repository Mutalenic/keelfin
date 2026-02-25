class AdjustBudgetsForInflationJob < ApplicationJob
  queue_as :default
  
  def perform
    latest_inflation = EconomicIndicator.latest_inflation
    
    unless latest_inflation
      Rails.logger.warn "No inflation data available for budget adjustment"
      return
    end
    
    # Convert annual inflation to monthly
    monthly_inflation = latest_inflation / 12
    
    adjusted_count = 0
    failed_count = 0
    Budget.where(inflation_adjusted: true).find_each do |budget|
      if budget.adjust_for_inflation!(monthly_inflation)
        adjusted_count += 1
      else
        failed_count += 1
        Rails.logger.warn "Failed to adjust budget #{budget.id}: #{budget.errors.full_messages.join(', ')}"
      end
    end
    
    Rails.logger.info "Adjusted #{adjusted_count} budgets for inflation (#{monthly_inflation}% monthly), #{failed_count} failed"
  rescue StandardError => e
    Rails.logger.error "Failed to adjust budgets for inflation: #{e.message}\n#{e.backtrace.join("\n")}"
    raise
  end
end
