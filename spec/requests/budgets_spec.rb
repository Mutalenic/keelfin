require 'rails_helper'

RSpec.describe 'Budgets', type: :request do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123') }
  let(:category) { user.categories.create!(name: 'Food', icon: '🍔') }
  let(:budget) { user.budgets.create!(category: category, monthly_limit: 5000) }

  before do
    sign_in user
  end

  describe 'GET /index' do
    it 'returns http success' do
      get budgets_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /new' do
    it 'returns http success' do
      get new_budget_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /create' do
    it 'creates a new budget' do
      expect do
        post budgets_path, params: { budget: { category_id: category.id, monthly_limit: 3000 } }
      end.to change(Budget, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'GET /edit' do
    it 'returns http success' do
      get edit_budget_path(budget)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /update' do
    it 'updates the budget' do
      patch budget_path(budget), params: { budget: { monthly_limit: 6000 } }
      expect(response).to have_http_status(:redirect)
      expect(budget.reload.monthly_limit).to eq(6000)
    end
  end

  describe 'DELETE /destroy' do
    it 'destroys the budget' do
      budget # create the budget
      expect do
        delete budget_path(budget)
      end.to change(Budget, :count).by(-1)
      expect(response).to have_http_status(:redirect)
    end
  end
end
