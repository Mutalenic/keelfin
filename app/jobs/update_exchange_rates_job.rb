class UpdateExchangeRatesJob < ApplicationJob
  queue_as :default
  
  def perform
    rate = ExchangeRateService.fetch_latest_usd_zmw
    return unless rate
    
    EconomicIndicator.create!(
      date: Date.current,
      usd_zmw_rate: rate,
      source: 'exchangerate-api.com'
    )
    
    Rails.logger.info "Updated USD/ZMW rate: #{rate}"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn "Exchange rate already exists for today: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Failed to update exchange rates: #{e.message}"
  end
end
