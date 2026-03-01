require 'rails_helper'

RSpec.describe AdjustBudgetsForInflationJob, type: :job do
  describe '#perform' do
    let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123') }
    let(:food_category) { user.categories.create!(name: 'Food', icon: '🍔') }
    let(:transport_category) { user.categories.create!(name: 'Transport', icon: '🚗') }

    context 'when inflation data is available' do
      let!(:indicator) { EconomicIndicator.create!(date: Date.current, inflation_rate: 10.0) }
      let!(:adjusted_budget) do
        user.budgets.create!(category: food_category, monthly_limit: 5000, inflation_adjusted: true)
      end
      let!(:non_adjusted_budget) do
        user.budgets.create!(category: transport_category, monthly_limit: 3000, inflation_adjusted: false)
      end

      it 'adjusts inflation-adjusted budgets' do
        described_class.new.perform
        adjusted_budget.reload
        # Monthly inflation = 10 / 12 = 0.833%
        # New limit = 5000 * (1 + 0.833/100) = 5041.67
        expected = (5000 * (1 + ((10.0 / 12) / 100))).round(2)
        expect(adjusted_budget.monthly_limit.to_f.round(2)).to eq(expected)
      end

      it 'does not adjust non-inflation-adjusted budgets' do
        expect do
          described_class.new.perform
          non_adjusted_budget.reload
        end.not_to(change(non_adjusted_budget, :monthly_limit))
      end

      it 'logs the number of budgets adjusted' do
        allow(Rails.logger).to receive(:info)
        described_class.new.perform
        expect(Rails.logger).to have_received(:info).with(/Adjusted \d+ budgets? for inflation/)
      end
    end

    context 'when no inflation data is available' do
      let!(:adjusted_budget) do
        user.budgets.create!(category: food_category, monthly_limit: 5000, inflation_adjusted: true)
      end

      it 'does not adjust budgets' do
        described_class.new.perform

        adjusted_budget.reload
        expect(adjusted_budget.monthly_limit).to eq(5000)
      end

      it 'logs warning message' do
        allow(Rails.logger).to receive(:warn)
        described_class.new.perform
        expect(Rails.logger).to have_received(:warn).with(/No inflation data available/).at_least(:once)
      end
    end

    context 'when inflation rate is zero' do
      let!(:indicator) { EconomicIndicator.create!(date: Date.current, inflation_rate: 0) }
      let!(:adjusted_budget) do
        user.budgets.create!(category: food_category, monthly_limit: 5000, inflation_adjusted: true)
      end

      it 'does not adjust budgets' do
        described_class.new.perform

        adjusted_budget.reload
        expect(adjusted_budget.monthly_limit).to eq(5000)
      end
    end
  end
end
