require 'net/http'
require 'json'

class ExchangeRateService
  def self.fetch_latest_usd_zmw
    url = URI("https://api.exchangerate-api.com/v4/latest/USD")
    response = Net::HTTP.get(url)
    data = JSON.parse(response)
    data['rates']['ZMW']
  rescue StandardError => e
    Rails.logger.error "Exchange rate fetch failed: #{e.message}"
    nil
  end
  
  def self.convert(amount, from_currency, to_currency)
    return amount if from_currency == to_currency
    
    rate = fetch_latest_usd_zmw
    return nil unless rate
    
    if from_currency == 'USD' && to_currency == 'ZMW'
      amount * rate
    elsif from_currency == 'ZMW' && to_currency == 'USD'
      amount / rate
    else
      nil
    end
  end
end
