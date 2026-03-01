require 'rails_helper'

RSpec.describe Debt, type: :model do
  let(:user) do
    User.create!(name: 'Test User', email: 'test@example.com', password: 'password123', monthly_income: 10_000)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { user.debts.build(lender_name: 'Test', principal_amount: 1000) }

    it { is_expected.to validate_presence_of(:lender_name) }
    it { is_expected.to validate_presence_of(:principal_amount) }
    it { is_expected.to validate_numericality_of(:principal_amount).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:interest_rate).is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:monthly_payment).is_greater_than(0).allow_nil }

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
    let!(:active_debt) do
      user.debts.create!(lender_name: 'Bayport', principal_amount: 50_000, status: 'active', monthly_payment: 2000)
    end
    let!(:paid_debt) do
      user.debts.create!(lender_name: 'Madison', principal_amount: 30_000, status: 'paid_off', monthly_payment: 1500)
    end

    it 'returns active debts' do
      expect(described_class.active).to include(active_debt)
      expect(described_class.active).not_to include(paid_debt)
    end

    it 'returns paid off debts' do
      expect(described_class.paid_off).to include(paid_debt)
      expect(described_class.paid_off).not_to include(active_debt)
    end
  end

  describe '#debt_to_income_ratio' do
    it 'calculates correct ratio when user has income' do
      debt = user.debts.create!(lender_name: 'Bayport', principal_amount: 50_000, monthly_payment: 2000)
      expect(debt.debt_to_income_ratio).to eq(20.0)
    end

    it 'returns 0 when user has no income' do
      user.update(monthly_income: nil)
      debt = user.debts.create!(lender_name: 'Bayport', principal_amount: 50_000, monthly_payment: 2000)
      expect(debt.debt_to_income_ratio).to eq(0)
    end
  end

  describe '#total_interest_cost' do
    it 'calculates total interest cost' do
      debt = user.debts.create!(
        lender_name: 'Bayport',
        principal_amount: 50_000,
        monthly_payment: 2500,
        start_date: Time.zone.today,
        end_date: Time.zone.today + 24.months
      )

      expected_total = 2500 * 24
      expected_interest = expected_total - 50_000
      expect(debt.total_interest_cost).to eq(expected_interest)
    end

    it 'returns 0 when dates are missing' do
      debt = user.debts.create!(lender_name: 'Bayport', principal_amount: 50_000, monthly_payment: 2500)
      expect(debt.total_interest_cost).to eq(0)
    end

    it 'returns 0 when end_date equals start_date' do
      debt = user.debts.create!(
        lender_name: 'Bayport',
        principal_amount: 50_000,
        monthly_payment: 2500,
        start_date: Time.zone.today,
        end_date: Time.zone.today
      )
      expect(debt.total_interest_cost).to eq(0)
    end

    it 'returns 0 when end_date is before start_date' do
      debt = user.debts.create!(
        lender_name: 'Bayport',
        principal_amount: 50_000,
        monthly_payment: 2500,
        start_date: Time.zone.today,
        end_date: Time.zone.today - 1.month
      )
      expect(debt.total_interest_cost).to eq(0)
    end
  end
end
