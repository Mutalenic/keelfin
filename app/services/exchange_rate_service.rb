require 'net/http'
require 'json'
require 'openssl'

class ExchangeRateService
  MAX_RETRIES = 3
  BASE_DELAY  = 1
  CACHE_KEY   = 'exchange_rate:usd_zmw'.freeze
  CACHE_TTL   = 6.hours

  # Public: returns cached USD→ZMW rate, fetching live only on cache miss.
  def self.fetch_latest_usd_zmw
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      fetch_from_api
    end
  rescue StandardError => e
    Rails.logger.error "Exchange rate cache error: #{e.class} - #{e.message}"
    Rails.cache.read(CACHE_KEY) # return stale value rather than nil
  end

  def self.convert(amount, from_currency, to_currency)
    return amount if from_currency == to_currency

    rate = fetch_latest_usd_zmw
    return nil unless rate

    if from_currency == 'USD' && to_currency == 'ZMW'
      amount * rate
    elsif from_currency == 'ZMW' && to_currency == 'USD'
      amount / rate
    end
  end

  # Private: performs the live HTTP request with exponential-backoff retries.
  def self.fetch_from_api(retries = 0)
    url = URI('https://api.exchangerate-api.com/v4/latest/USD')

    response = Net::HTTP.start(url.host, url.port,
                               use_ssl: true,
                               verify_mode: OpenSSL::SSL::VERIFY_PEER,
                               open_timeout: 5,
                               read_timeout: 10) do |http|
      request = Net::HTTP::Get.new(url)
      http.request(request).body
    end

    data = JSON.parse(response)
    return nil unless data.is_a?(Hash) && data['rates'].is_a?(Hash)

    data['rates']['ZMW']
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => e
    Rails.logger.error "Exchange rate API error (attempt #{retries + 1}/#{MAX_RETRIES}): #{e.message}"

    if retries < MAX_RETRIES
      sleep(BASE_DELAY * (2**retries))
      fetch_from_api(retries + 1)
    else
      Rails.logger.error "Exchange rate API failed after #{MAX_RETRIES} attempts"
      nil
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Exchange rate JSON parse error: #{e.message}"
    nil
  rescue => e
    Rails.logger.error "Unexpected error fetching exchange rate: #{e.class} - #{e.message}"
    nil
  end
  private_class_method :fetch_from_api
end
