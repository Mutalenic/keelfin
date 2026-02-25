require 'rails_helper'

RSpec.describe Debt, type: :model do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123', monthly_income: 10000) }
  
  describe 'associations' do
    it { should belong_to(:user) }
  end
  
  describe 'validations' do
    subject { user.debts.build(lender_name: 'Test', principal_amount: 1000) }
    
    it { should validate_presence_of(:lender_name) }
    it { should validate_presence_of(:principal_amount) }
    it { should validate_numericality_of(:principal_amount).is_greater_than(0) }
    it { should validate_numericality_of(:interest_rate).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:monthly_payment).is_greater_than(0).allow_nil }
    it 'validates status inclusion' do
      debt = user.debts.build(lender_name: 'Test', principal_amount: 1000, status: 'invalid')
      expect(debt).not_to be_valid
      expect(debt.errors[:status]).to include('invalid is not a valid status')
      
      debt.status = 'active'
      expect(debt).to be_valid
      
      debt.status = nil
      expect(debt).to be_valid
    end
  end
  
  describe 'scopes' do
    let!(:active_debt) { user.debts.create!(lender_name: 'Bayport', principal_amount: 50000, status: 'active', monthly_payment: 2000) }
    let!(:paid_debt) { user.debts.create!(lender_name: 'Madison', principal_amount: 30000, status: 'paid_off', monthly_payment: 1500) }
    
    it 'returns active debts' do
      expect(Debt.active).to include(active_debt)
      expect(Debt.active).not_to include(paid_debt)
    end
    
    it 'returns paid off debts' do
      expect(Debt.paid_off).to include(paid_debt)
      expect(Debt.paid_off).not_to include(active_debt)
    end
  end
  
  describe '#debt_to_income_ratio' do
    it 'calculates correct ratio when user has income' do
      debt = user.debts.create!(lender_name: 'Bayport', principal_amount: 50000, monthly_payment: 2000)
      expect(debt.debt_to_income_ratio).to eq(20.0)
    end
    
    it 'returns 0 when user has no income' do
      user.update(monthly_income: nil)
      debt = user.debts.create!(lender_name: 'Bayport', principal_amount: 50000, monthly_payment: 2000)
      expect(debt.debt_to_income_ratio).to eq(0)
    end
  end
  
  describe '#total_interest_cost' do
    it 'calculates total interest cost' do
      debt = user.debts.create!(
        lender_name: 'Bayport',
        principal_amount: 50000,
        monthly_payment: 2500,
        start_date: Date.today,
        end_date: Date.today + 24.months
      )
      
      expected_total = 2500 * 24
      expected_interest = expected_total - 50000
      expect(debt.total_interest_cost).to eq(expected_interest)
    end
    
    it 'returns 0 when dates are missing' do
      debt = user.debts.create!(lender_name: 'Bayport', principal_amount: 50000, monthly_payment: 2500)
      expect(debt.total_interest_cost).to eq(0)
    end
    
    it 'returns 0 when end_date equals start_date' do
      debt = user.debts.create!(
        lender_name: 'Bayport',
        principal_amount: 50000,
        monthly_payment: 2500,
        start_date: Date.today,
        end_date: Date.today
      )
      expect(debt.total_interest_cost).to eq(0)
    end
    
    it 'returns 0 when end_date is before start_date' do
      debt = user.debts.create!(
        lender_name: 'Bayport',
        principal_amount: 50000,
        monthly_payment: 2500,
        start_date: Date.today,
        end_date: Date.today - 1.month
      )
      expect(debt.total_interest_cost).to eq(0)
    end
  end
end
