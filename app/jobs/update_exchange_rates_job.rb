class UpdateExchangeRatesJob < ApplicationJob
  queue_as :default
  
  def perform
    rate = ExchangeRateService.fetch_latest_usd_zmw
    return unless rate
    
    indicator = EconomicIndicator.find_or_create_by(date: Date.current) do |ind|
      ind.usd_zmw_rate = rate
      ind.source = 'exchangerate-api.com'
    end
    
    # Update if it already existed
    if indicator.persisted? && indicator.usd_zmw_rate != rate
      indicator.update(usd_zmw_rate: rate, source: 'exchangerate-api.com')
    end
    
    Rails.logger.info "Updated USD/ZMW rate: #{rate}"
  rescue StandardError => e
    Rails.logger.error "Failed to update exchange rates: #{e.message}"
  end
end
