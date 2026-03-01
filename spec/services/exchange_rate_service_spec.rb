require 'rails_helper'

RSpec.describe ExchangeRateService do
  describe '.fetch_latest_usd_zmw' do
    it 'returns exchange rate on success' do
      stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
        .to_return(
          status: 200,
          body: { rates: { ZMW: 25.5 } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      rate = described_class.fetch_latest_usd_zmw
      expect(rate).to eq(25.5)
    end

    it 'returns nil on network timeout' do
      stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
        .to_timeout

      rate = described_class.fetch_latest_usd_zmw
      expect(rate).to be_nil
    end

    it 'returns nil on invalid JSON' do
      stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
        .to_return(status: 200, body: 'invalid json')

      rate = described_class.fetch_latest_usd_zmw
      expect(rate).to be_nil
    end

    it 'returns nil when rates are missing' do
      stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
        .to_return(
          status: 200,
          body: { data: 'no rates' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      rate = described_class.fetch_latest_usd_zmw
      expect(rate).to be_nil
    end

    it 'logs errors appropriately' do
      stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
        .to_raise(SocketError.new('Network error'))

      allow(Rails.logger).to receive(:error)

      described_class.fetch_latest_usd_zmw

      expect(Rails.logger).to have_received(:error).with(/Exchange rate network error/)
    end
  end

  describe '.convert' do
    before do
      allow(described_class).to receive(:fetch_latest_usd_zmw).and_return(25.0)
    end

    it 'converts USD to ZMW' do
      result = described_class.convert(100, 'USD', 'ZMW')
      expect(result).to eq(2500)
    end

    it 'converts ZMW to USD' do
      result = described_class.convert(2500, 'ZMW', 'USD')
      expect(result).to eq(100)
    end

    it 'returns amount when currencies are the same' do
      result = described_class.convert(100, 'USD', 'USD')
      expect(result).to eq(100)
    end

    it 'returns nil when rate fetch fails' do
      allow(described_class).to receive(:fetch_latest_usd_zmw).and_return(nil)
      result = described_class.convert(100, 'USD', 'ZMW')
      expect(result).to be_nil
    end
  end
end
