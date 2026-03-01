require 'rails_helper'

RSpec.describe 'RecurringTransactions', type: :request do
  let(:user) { create(:user) }
  let!(:category) { create(:category, user: user) }
  let!(:rt) { create(:recurring_transaction, user: user, category: category) }

  before { sign_in user }

  describe 'GET /recurring_transactions' do
    it 'returns http success' do
      get recurring_transactions_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /recurring_transactions/new' do
    it 'returns http success' do
      get new_recurring_transaction_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /recurring_transactions' do
    let(:valid_params) do
      { recurring_transaction: {
        name: 'Airtel Money',
        amount: 100,
        frequency: 'monthly',
        start_date: Date.current,
        category_id: category.id,
        active: true
      } }
    end

    it 'creates a recurring transaction and redirects' do
      expect do
        post recurring_transactions_path, params: valid_params
      end.to change(RecurringTransaction, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    it 'renders new on invalid params' do
      post recurring_transactions_path,
           params: { recurring_transaction: { name: '', amount: -1 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /recurring_transactions/:id' do
    it 'returns http success' do
      get recurring_transaction_path(rt)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /recurring_transactions/:id/edit' do
    it 'returns http success' do
      get edit_recurring_transaction_path(rt)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /recurring_transactions/:id' do
    it 'updates and redirects' do
      patch recurring_transaction_path(rt), params: { recurring_transaction: { name: 'New Name' } }
      expect(response).to have_http_status(:redirect)
      expect(rt.reload.name).to eq('New Name')
    end
  end

  describe 'PATCH /recurring_transactions/:id/toggle_active' do
    it 'toggles active status and redirects' do
      patch toggle_active_recurring_transaction_path(rt)
      expect(response).to have_http_status(:redirect)
      expect(rt.reload.active).to be(false)
    end
  end

  describe 'DELETE /recurring_transactions/:id' do
    it 'destroys the record and redirects' do
      expect do
        delete recurring_transaction_path(rt)
      end.to change(RecurringTransaction, :count).by(-1)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'authorization: other user cannot access' do
    let(:other_user) { create(:user) }

    before { sign_in other_user }

    it "redirects away from another user's recurring transaction" do
      get recurring_transaction_path(rt)
      expect(response).to have_http_status(:redirect)
    end
  end
end
