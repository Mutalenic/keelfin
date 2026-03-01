require 'rails_helper'

RSpec.describe 'FinancialGoals', type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:financial_goal, user: user) }

  before { sign_in user }

  describe 'GET /financial_goals' do
    it 'returns http success' do
      get financial_goals_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /financial_goals/new' do
    it 'returns http success' do
      get new_financial_goal_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /financial_goals' do
    let(:valid_params) do
      { financial_goal: {
        name: 'Car Fund',
        goal_type: 'saving',
        target_amount: 20_000,
        current_amount: 0,
        start_date: Date.current,
        target_date: 1.year.from_now.to_date
      } }
    end

    it 'creates a goal and redirects' do
      expect do
        post financial_goals_path, params: valid_params
      end.to change(FinancialGoal, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    it 'renders new on invalid params' do
      post financial_goals_path, params: { financial_goal: { name: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /financial_goals/:id' do
    it 'returns http success' do
      get financial_goal_path(goal)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /financial_goals/:id/edit' do
    it 'returns http success' do
      get edit_financial_goal_path(goal)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /financial_goals/:id' do
    it 'updates the goal and redirects' do
      patch financial_goal_path(goal), params: { financial_goal: { name: 'Updated Goal' } }
      expect(response).to have_http_status(:redirect)
      expect(goal.reload.name).to eq('Updated Goal')
    end
  end

  describe 'PATCH /financial_goals/:id/update_progress' do
    it 'updates the progress amount and redirects' do
      patch update_progress_financial_goal_path(goal),
            params: { current_amount: 10_000 }
      expect(response).to have_http_status(:redirect)
      expect(goal.reload.current_amount.to_f).to eq(10_000.0)
    end
  end

  describe 'DELETE /financial_goals/:id' do
    it 'destroys the goal and redirects' do
      expect do
        delete financial_goal_path(goal)
      end.to change(FinancialGoal, :count).by(-1)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'authorization: other user cannot access' do
    let(:other_user) { create(:user) }

    before { sign_in other_user }

    it "redirects away from another user's goal" do
      get financial_goal_path(goal)
      expect(response).to have_http_status(:redirect)
    end
  end
end
