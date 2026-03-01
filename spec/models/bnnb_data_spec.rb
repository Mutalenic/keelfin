require 'rails_helper'

RSpec.describe BnnbData, type: :model do
  describe 'validations' do
    subject { described_class.new(month: Date.current.beginning_of_month, location: 'Lusaka') }

    it { is_expected.to validate_presence_of(:month) }
    it { is_expected.to validate_uniqueness_of(:month).scoped_to(:location) }

    it 'allows nil values for basket fields' do
      bnnb = described_class.create(month: Date.current.beginning_of_month, location: 'Lusaka')
      expect(bnnb).to be_valid
    end

    it 'validates numericality when values are present' do
      bnnb = described_class.new(
        month: Date.current.beginning_of_month,
        total_basket: -100,
        food_basket: 500,
        non_food_basket: 300
      )
      expect(bnnb).not_to be_valid
      expect(bnnb.errors[:total_basket]).to be_present
    end
  end

  describe '.compare_user_spending' do
    let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123') }
    let(:food_category) { user.categories.create!(name: 'Food & Groceries', icon: '🍔') }
    let(:month) { Date.current.beginning_of_month }

    context 'when bnnb data exists with food_basket' do
      let!(:bnnb) do
        described_class.create!(month: month, food_basket: 2000, total_basket: 5000, non_food_basket: 3000)
      end

      it 'compares user spending to BNNB data' do
        user.payments.create!(category: food_category, name: 'Groceries', amount: 1500, created_at: month)

        result = described_class.compare_user_spending(user, month)

        expect(result).not_to be_nil
        expect(result[:bnnb_food]).to eq(2000)
        expect(result[:user_food]).to eq(1500)
        expect(result[:difference]).to eq(-500)
        expect(result[:percentage]).to eq(75.0)
      end
    end

    context 'when bnnb data has nil food_basket' do
      let!(:bnnb) { described_class.create!(month: month, food_basket: nil, total_basket: 5000, non_food_basket: 3000) }

      it 'returns nil to avoid null pointer exception' do
        user.payments.create!(category: food_category, name: 'Groceries', amount: 1500, created_at: month)

        result = described_class.compare_user_spending(user, month)

        expect(result).to be_nil
      end
    end

    context 'when no bnnb data exists' do
      it 'returns nil' do
        result = described_class.compare_user_spending(user, month)
        expect(result).to be_nil
      end
    end

    context 'when food_basket is very small' do
      let!(:bnnb) do
        described_class.create!(month: month, food_basket: 0.01, total_basket: 5000, non_food_basket: 4999.99)
      end

      it 'calculates percentage correctly' do
        user.payments.create!(category: food_category, name: 'Groceries', amount: 1500, created_at: month)

        result = described_class.compare_user_spending(user, month)

        expect(result[:percentage]).to be > 0
      end
    end
  end

  describe 'scopes' do
    let!(:old_data) do
      described_class.create!(month: 2.years.ago, food_basket: 1000, total_basket: 3000, non_food_basket: 2000)
    end
    let!(:recent_data) do
      described_class.create!(month: Date.current.beginning_of_month, food_basket: 2000, total_basket: 5000,
                              non_food_basket: 3000)
    end

    it 'returns recent data' do
      expect(described_class.recent).to include(recent_data)
      expect(described_class.recent.count).to be <= 12
    end

    it 'filters by location' do
      lusaka_data = described_class.create!(
        month: 1.month.ago, location: 'Lusaka', food_basket: 2000, total_basket: 5000,
        non_food_basket: 3000
      )
      ndola_data = described_class.create!(month: 1.month.ago, location: 'Ndola', food_basket: 1800, total_basket: 4500,
                                           non_food_basket: 2700)

      expect(described_class.for_location('Lusaka')).to include(lusaka_data)
      expect(described_class.for_location('Lusaka')).not_to include(ndola_data)
    end
  end
end
