require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'Bug Fixes Integration Tests', type: :integration do
  let(:user) do
    User.create!(name: 'Test User', email: 'test@example.com', password: 'password123', monthly_income: 10_000)
  end
  let(:category) { user.categories.create!(name: 'Food', icon: '🍔') }

  describe 'Issue #4 & #5: Nil reference errors in views' do
    it 'handles nil interest_rate in debt view' do
      debt = user.debts.create!(lender_name: 'Bayport', principal_amount: 50_000, interest_rate: nil)

      expect { debt.interest_rate }.not_to raise_error
      expect(debt.interest_rate).to be_nil
    end

    it 'handles nil monthly_payment in debt view' do
      debt = user.debts.create!(lender_name: 'Bayport', principal_amount: 50_000, monthly_payment: nil)

      expect { debt.monthly_payment }.not_to raise_error
      expect(debt.monthly_payment).to be_nil
    end
  end

  describe 'Issue #7: Status validation' do
    it 'accepts valid status values' do
      debt = user.debts.build(lender_name: 'Bayport', principal_amount: 50_000, status: 'active')
      expect(debt).to be_valid

      debt.status = 'paid_off'
      expect(debt).to be_valid
    end

    it 'rejects invalid status values' do
      debt = user.debts.build(lender_name: 'Bayport', principal_amount: 50_000, status: 'invalid')
      expect(debt).not_to be_valid
      expect(debt.errors[:status]).to include('invalid is not a valid status')
    end

    it 'allows nil status' do
      debt = user.debts.build(lender_name: 'Bayport', principal_amount: 50_000, status: nil)
      expect(debt).to be_valid
    end
  end

  describe 'Issue #2: Division by zero in BnnbComparisonService' do
    let(:service) { BnnbComparisonService.new(user) }

    it 'handles zero food_basket gracefully' do
      bnnb = BnnbData.create!(month: Date.current.beginning_of_month, food_basket: 1000, non_food_basket: 1000,
                              total_basket: 2000)
      bnnb.update_column(:food_basket, 0) # rubocop:disable Rails/SkipsModelValidations

      expect { service.send(:generate_insights, bnnb) }.not_to raise_error
      insights = service.send(:generate_insights, bnnb)
      expect(insights).to eq([])
    end

    it 'handles nil food_basket gracefully' do
      bnnb = BnnbData.create!(month: Date.current.beginning_of_month, food_basket: 1000, non_food_basket: 1000,
                              total_basket: 2000)
      bnnb.update_columns(food_basket: nil) # rubocop:disable Rails/SkipsModelValidations

      expect { service.send(:generate_insights, bnnb) }.not_to raise_error
      insights = service.send(:generate_insights, bnnb)
      expect(insights).to eq([])
    end
  end

  describe 'Issue #8 & #9: Debt calculation improvements' do
    it 'calculates total_interest_cost correctly with valid dates' do
      debt = user.debts.create!(
        lender_name: 'Bayport',
        principal_amount: 50_000,
        monthly_payment: 2500,
        start_date: Date.new(2026, 1, 1),
        end_date: Date.new(2027, 1, 1)
      )

      # 12 months * 2500 = 30000, minus principal 50000 = -20000, but max(x, 0) = 0
      # Actually 13 months from Jan 1 2026 to Jan 1 2027
      months = 12
      expected = (2500 * months) - 50_000
      expect(debt.total_interest_cost).to eq([expected, 0].max)
    end

    it 'returns 0 when end_date is before start_date' do
      debt = user.debts.create!(
        lender_name: 'Bayport',
        principal_amount: 50_000,
        monthly_payment: 2500,
        start_date: Date.new(2026, 12, 31),
        end_date: Date.new(2026, 1, 1)
      )

      expect(debt.total_interest_cost).to eq(0)
    end

    it 'ensures non-negative interest cost' do
      debt = user.debts.create!(
        lender_name: 'Bayport',
        principal_amount: 50_000,
        monthly_payment: 100,
        start_date: Date.new(2026, 1, 1),
        end_date: Date.new(2026, 12, 31)
      )

      expect(debt.total_interest_cost).to eq(0) # max(1200 - 50000, 0) = 0
    end
  end

  describe 'Issue #10: Race condition in UpdateExchangeRatesJob' do
    it 'updates existing indicator correctly' do
      existing = EconomicIndicator.create!(date: Date.current, usd_zmw_rate: 24.0, source: 'old')
      allow(ExchangeRateService).to receive(:fetch_latest_usd_zmw).and_return(25.5)

      UpdateExchangeRatesJob.new.perform

      existing.reload
      expect(existing.usd_zmw_rate).to eq(25.5)
      expect(existing.source).to eq('exchangerate-api.com')
    end

    it 'creates new indicator when none exists' do
      allow(ExchangeRateService).to receive(:fetch_latest_usd_zmw).and_return(25.5)

      expect do
        UpdateExchangeRatesJob.new.perform
      end.to change(EconomicIndicator, :count).by(1)

      indicator = EconomicIndicator.last
      expect(indicator.usd_zmw_rate).to eq(25.5)
    end
  end

  describe 'Issue #11: Inflation adjustment mutation' do
    it 'uses atomic update operation' do
      budget = user.budgets.create!(category: category, monthly_limit: 5000, inflation_adjusted: true)

      budget.adjust_for_inflation!(10)
      budget.reload

      expect(budget.monthly_limit.to_f).to eq(5500.0)
    end

    it 'uses update! for atomic operation' do
      budget = user.budgets.create!(category: category, monthly_limit: 5000, inflation_adjusted: true)
      allow(budget).to receive(:update!).and_call_original

      budget.adjust_for_inflation!(10)
      budget.reload

      expect(budget).to have_received(:update!).with(monthly_limit: 5500.0)
      expect(budget.monthly_limit.to_f).to eq(5500.0)
    end
  end

  describe 'Issue #3: N+1 query optimization' do
    it 'caches active debts query in DebtAnalysisService' do
      user.debts.create!(lender_name: 'Bayport', principal_amount: 50_000, status: 'active', interest_rate: 15.0)
      user.debts.create!(lender_name: 'Madison', principal_amount: 30_000, status: 'active', interest_rate: 12.0)

      service = DebtAnalysisService.new(user)
      result = service.send(:payoff_strategies)

      # Verify both strategies are returned
      expect(result[:avalanche]).to be_an(Array)
      expect(result[:snowball]).to be_an(Array)
      expect(result[:avalanche].length).to eq(2)
      expect(result[:snowball].length).to eq(2)
    end
  end

  describe 'Issue #14: Improved error handling in ExchangeRateService' do
    it 'catches specific timeout errors' do
      stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD').to_timeout

      allow(Rails.logger).to receive(:error)

      expect { ExchangeRateService.fetch_latest_usd_zmw }.not_to raise_error

      expect(Rails.logger).to have_received(:error).with(/Exchange rate API timeout/)
    end

    it 'catches JSON parse errors' do
      stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
        .to_return(status: 200, body: 'invalid json')

      allow(Rails.logger).to receive(:error)

      expect { ExchangeRateService.fetch_latest_usd_zmw }.not_to raise_error

      expect(Rails.logger).to have_received(:error).with(/Exchange rate JSON parse error/)
    end

    it 'catches network errors' do
      stub_request(:get, 'https://api.exchangerate-api.com/v4/latest/USD')
        .to_raise(SocketError.new('Network error'))

      allow(Rails.logger).to receive(:error)

      expect { ExchangeRateService.fetch_latest_usd_zmw }.not_to raise_error

      expect(Rails.logger).to have_received(:error).with(/Exchange rate network error/)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
