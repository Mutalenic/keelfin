require 'rails_helper'

RSpec.describe UpdateExchangeRatesJob, type: :job do
  describe '#perform' do
    context 'when exchange rate is successfully fetched' do
      before do
        allow(ExchangeRateService).to receive(:fetch_latest_usd_zmw).and_return(25.5)
      end
      
      it 'creates a new economic indicator' do
        expect {
          UpdateExchangeRatesJob.new.perform
        }.to change(EconomicIndicator, :count).by(1)
        
        indicator = EconomicIndicator.last
        expect(indicator.usd_zmw_rate).to eq(25.5)
        expect(indicator.source).to eq('exchangerate-api.com')
      end
      
      it 'updates existing economic indicator for today' do
        existing = EconomicIndicator.create!(date: Date.current, usd_zmw_rate: 24.0, source: 'old')
        
        expect {
          UpdateExchangeRatesJob.new.perform
        }.not_to change(EconomicIndicator, :count)
        
        existing.reload
        expect(existing.usd_zmw_rate).to eq(25.5)
        expect(existing.source).to eq('exchangerate-api.com')
      end
      
      it 'logs success message' do
        expect(Rails.logger).to receive(:info).with(/Updated USD\/ZMW rate: 25.5/)
        UpdateExchangeRatesJob.new.perform
      end
    end
    
    context 'when exchange rate fetch fails' do
      before do
        allow(ExchangeRateService).to receive(:fetch_latest_usd_zmw).and_return(nil)
      end
      
      it 'does not create an indicator' do
        expect {
          UpdateExchangeRatesJob.new.perform
        }.not_to change(EconomicIndicator, :count)
      end
    end
    
    context 'when save fails' do
      before do
        allow(ExchangeRateService).to receive(:fetch_latest_usd_zmw).and_return(25.5)
        allow_any_instance_of(EconomicIndicator).to receive(:save).and_return(false)
        allow_any_instance_of(EconomicIndicator).to receive(:errors).and_return(
          double(full_messages: ['Validation failed'])
        )
      end
      
      it 'logs error message' do
        expect(Rails.logger).to receive(:error).with(/Failed to save exchange rate/)
        UpdateExchangeRatesJob.new.perform
      end
    end
    
    context 'when an exception occurs' do
      before do
        allow(ExchangeRateService).to receive(:fetch_latest_usd_zmw).and_raise(StandardError.new('Unexpected error'))
      end
      
      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to update exchange rates/)
        UpdateExchangeRatesJob.new.perform
      end
    end
  end
end
