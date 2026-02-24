require 'rails_helper'

RSpec.describe BnnbComparisonService do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123', monthly_income: 15000) }
  let(:category) { user.categories.create!(name: 'Food', icon: '🍔') }
  let(:month) { Date.current.beginning_of_month }
  let(:service) { BnnbComparisonService.new(user, month) }
  
  describe '#compare' do
    context 'when BNNB data exists' do
      let!(:bnnb_data) { BnnbData.create!(month: month, food_basket: 3000, non_food_basket: 2000, total_basket: 5000) }
      
      before do
        user.payments.create!(category: category, name: 'Groceries', amount: 2500, created_at: month)
      end
      
      it 'returns comparison data' do
        result = service.compare
        
        expect(result).to be_a(Hash)
        expect(result[:bnnb_total]).to eq(5000)
        expect(result[:user_total]).to eq(2500)
        expect(result[:bnnb_food]).to eq(3000)
        expect(result[:user_food]).to eq(2500)
      end
      
      it 'generates insights' do
        result = service.compare
        expect(result[:insights]).to be_an(Array)
      end
    end
    
    context 'when BNNB data does not exist' do
      it 'returns nil' do
        expect(service.compare).to be_nil
      end
    end
  end
  
  describe '#generate_insights' do
    let!(:bnnb_data) { BnnbData.create!(month: month, food_basket: 3000, non_food_basket: 2000, total_basket: 5000) }
    
    it 'handles nil food_basket gracefully' do
      bnnb_data.update_columns(food_basket: nil)
      bnnb_data.reload
      result = service.send(:generate_insights, bnnb_data)
      expect(result).to eq([])
    end
    
    it 'handles zero food_basket gracefully' do
      bnnb_data.update_column(:food_basket, 0)
      bnnb_data.reload
      result = service.send(:generate_insights, bnnb_data)
      expect(result).to eq([])
    end
    
    it 'generates positive insight when spending is below average' do
      user.payments.create!(category: category, name: 'Groceries', amount: 2000, created_at: month)
      result = service.send(:generate_insights, bnnb_data)
      
      expect(result.any? { |i| i.include?('below JCTR average') }).to be true
    end
    
    it 'generates warning when spending is above average' do
      user.payments.create!(category: category, name: 'Groceries', amount: 4000, created_at: month)
      result = service.send(:generate_insights, bnnb_data)
      
      expect(result.any? { |i| i.include?('above JCTR average') }).to be true
    end
    
    it 'generates alert when income is below basic needs' do
      user.update(monthly_income: 4000)
      result = service.send(:generate_insights, bnnb_data)
      
      expect(result.any? { |i| i.include?('below JCTR basic needs') }).to be true
    end
  end
end
