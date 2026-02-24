require 'rails_helper'

RSpec.describe Budget, type: :model do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123') }
  let(:category) { user.categories.create!(name: 'Food', icon: '🍔') }
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:category) }
  end
  
  describe 'validations' do
    it { should validate_presence_of(:monthly_limit) }
    it { should validate_numericality_of(:monthly_limit).is_greater_than(0) }
  end
  
  describe '#current_spending' do
    let(:budget) { user.budgets.create!(category: category, monthly_limit: 5000) }
    
    it 'calculates current month spending' do
      user.payments.create!(category: category, name: 'Groceries', amount: 1000, created_at: Date.current)
      user.payments.create!(category: category, name: 'Restaurant', amount: 500, created_at: Date.current)
      
      expect(budget.current_spending).to eq(1500)
    end
    
    it 'excludes spending from other months' do
      user.payments.create!(category: category, name: 'Groceries', amount: 1000, created_at: Date.current)
      user.payments.create!(category: category, name: 'Old', amount: 500, created_at: 2.months.ago)
      
      expect(budget.current_spending).to eq(1000)
    end
  end
  
  describe '#remaining_budget' do
    let(:budget) { user.budgets.create!(category: category, monthly_limit: 5000) }
    
    it 'calculates remaining budget' do
      user.payments.create!(category: category, name: 'Groceries', amount: 1500, created_at: Date.current)
      
      expect(budget.remaining_budget).to eq(3500)
    end
  end
  
  describe '#percentage_used' do
    let(:budget) { user.budgets.create!(category: category, monthly_limit: 5000) }
    
    it 'calculates percentage used' do
      user.payments.create!(category: category, name: 'Groceries', amount: 2500, created_at: Date.current)
      
      expect(budget.percentage_used).to eq(50.0)
    end
    
    it 'returns 0 when limit is zero' do
      budget.update(monthly_limit: 0)
      expect(budget.percentage_used).to eq(0)
    end
  end
  
  describe '#is_overspent?' do
    let(:budget) { user.budgets.create!(category: category, monthly_limit: 5000) }
    
    it 'returns true when overspent' do
      user.payments.create!(category: category, name: 'Groceries', amount: 6000, created_at: Date.current)
      
      expect(budget.is_overspent?).to be true
    end
    
    it 'returns false when under budget' do
      user.payments.create!(category: category, name: 'Groceries', amount: 3000, created_at: Date.current)
      
      expect(budget.is_overspent?).to be false
    end
  end
  
  describe '#adjust_for_inflation!' do
    let(:budget) { user.budgets.create!(category: category, monthly_limit: 5000, inflation_adjusted: true) }
    
    it 'adjusts budget for inflation' do
      budget.adjust_for_inflation!(10)
      expect(budget.monthly_limit).to eq(5500)
    end
    
    it 'does not adjust when inflation_adjusted is false' do
      budget.update(inflation_adjusted: false)
      original_limit = budget.monthly_limit
      budget.adjust_for_inflation!(10)
      expect(budget.monthly_limit).to eq(original_limit)
    end
  end
end
