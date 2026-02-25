require 'rails_helper'

RSpec.describe AdjustBudgetsForInflationJob, type: :job do
  describe '#perform' do
    let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123') }
    let(:category1) { user.categories.create!(name: 'Food', icon: '🍔') }
    let(:category2) { user.categories.create!(name: 'Transport', icon: '🚗') }
    
    context 'when inflation data is available' do
      let!(:indicator) { EconomicIndicator.create!(date: Date.current, inflation_rate: 10.0) }
      let!(:adjusted_budget) { user.budgets.create!(category: category1, monthly_limit: 5000, inflation_adjusted: true) }
      let!(:non_adjusted_budget) { user.budgets.create!(category: category2, monthly_limit: 3000, inflation_adjusted: false) }
      
      it 'adjusts inflation-adjusted budgets' do
        AdjustBudgetsForInflationJob.new.perform
        adjusted_budget.reload
        # Monthly inflation = 10 / 12 = 0.833%
        # New limit = 5000 * (1 + 0.833/100) = 5041.67
        expected = (5000 * (1 + (10.0/12)/100)).round(2)
        expect(adjusted_budget.monthly_limit.to_f.round(2)).to eq(expected)
      end
      
      it 'does not adjust non-inflation-adjusted budgets' do
        expect {
          AdjustBudgetsForInflationJob.new.perform
          non_adjusted_budget.reload
        }.not_to change { non_adjusted_budget.monthly_limit }
      end
      
      it 'logs the number of budgets adjusted' do
        expect(Rails.logger).to receive(:info).with(/Adjusted \d+ budgets? for inflation/)
        AdjustBudgetsForInflationJob.new.perform
      end
    end
    
    context 'when no inflation data is available' do
      let!(:adjusted_budget) { user.budgets.create!(category: category1, monthly_limit: 5000, inflation_adjusted: true) }
      
      it 'does not adjust budgets' do
        AdjustBudgetsForInflationJob.new.perform
        
        adjusted_budget.reload
        expect(adjusted_budget.monthly_limit).to eq(5000)
      end
      
      it 'logs warning message' do
        expect(Rails.logger).to receive(:warn).with(/No inflation data available/).at_least(:once)
        AdjustBudgetsForInflationJob.new.perform
      end
    end
    
    context 'when inflation rate is zero' do
      let!(:indicator) { EconomicIndicator.create!(date: Date.current, inflation_rate: 0) }
      let!(:adjusted_budget) { user.budgets.create!(category: category1, monthly_limit: 5000, inflation_adjusted: true) }
      
      it 'does not adjust budgets' do
        AdjustBudgetsForInflationJob.new.perform
        
        adjusted_budget.reload
        expect(adjusted_budget.monthly_limit).to eq(5000)
      end
    end
  end
end
