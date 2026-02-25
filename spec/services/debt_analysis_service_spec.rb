require 'rails_helper'

RSpec.describe DebtAnalysisService do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123', monthly_income: 10000) }
  let(:service) { DebtAnalysisService.new(user) }
  
  describe '#analyze' do
    context 'with no debts' do
      it 'returns zero values' do
        result = service.analyze
        
        expect(result[:total_debt]).to eq(0)
        expect(result[:monthly_payments]).to eq(0)
        expect(result[:debt_to_income]).to eq(0)
        expect(result[:is_over_indebted]).to be false
        expect(result[:recommendations]).to be_empty
      end
    end
    
    context 'with debts under 40% threshold' do
      before do
        user.debts.create!(lender_name: 'Bayport', principal_amount: 50000, monthly_payment: 2000, status: 'active')
        user.debts.create!(lender_name: 'Madison', principal_amount: 30000, monthly_payment: 1500, status: 'active')
      end
      
      it 'calculates correct totals' do
        result = service.analyze
        
        expect(result[:total_debt]).to eq(80000)
        expect(result[:monthly_payments]).to eq(3500)
        expect(result[:debt_to_income]).to eq(35.0)
        expect(result[:is_over_indebted]).to be false
        expect(result[:recommendations]).to be_empty
      end
    end
    
    context 'with debts over 40% threshold' do
      before do
        user.debts.create!(lender_name: 'Bayport', principal_amount: 50000, monthly_payment: 3000, status: 'active')
        user.debts.create!(lender_name: 'Madison', principal_amount: 30000, monthly_payment: 2000, status: 'active')
      end
      
      it 'identifies over-indebtedness and provides recommendations' do
        result = service.analyze
        
        expect(result[:debt_to_income]).to eq(50.0)
        expect(result[:is_over_indebted]).to be true
        expect(result[:recommendations]).not_to be_empty
        expect(result[:recommendations].first).to include('50.0%')
      end
    end
    
    context 'payoff strategies' do
      before do
        user.debts.create!(lender_name: 'High Interest', principal_amount: 50000, monthly_payment: 3000, interest_rate: 25, status: 'active')
        user.debts.create!(lender_name: 'Low Interest', principal_amount: 30000, monthly_payment: 2000, interest_rate: 10, status: 'active')
        user.debts.create!(lender_name: 'Small Debt', principal_amount: 5000, monthly_payment: 500, interest_rate: 15, status: 'active')
      end
      
      it 'provides avalanche strategy (highest interest first)' do
        result = service.analyze
        avalanche = result[:payoff_strategies][:avalanche]
        
        expect(avalanche.first[0]).to eq('High Interest')
        expect(avalanche.first[1]).to eq(25)
      end
      
      it 'provides snowball strategy (smallest balance first)' do
        result = service.analyze
        snowball = result[:payoff_strategies][:snowball]
        
        expect(snowball.first[0]).to eq('Small Debt')
        expect(snowball.first[1]).to eq(5000)
      end
    end
  end
end
