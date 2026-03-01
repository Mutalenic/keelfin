class UpdateExchangeRatesJob < ApplicationJob
  queue_as :default

  def perform
    rate = ExchangeRateService.fetch_latest_usd_zmw
    return unless rate

    indicator = EconomicIndicator.find_or_initialize_by(date: Date.current)
    indicator.usd_zmw_rate = rate
    indicator.source = 'exchangerate-api.com'

    if indicator.save
      Rails.logger.info "Updated USD/ZMW rate: #{rate}"
    else
      Rails.logger.error "Failed to save exchange rate: #{indicator.errors.full_messages.join(', ')}"
    end
  rescue StandardError => e
    Rails.logger.error "Failed to update exchange rates: #{e.message}"
  end
end
