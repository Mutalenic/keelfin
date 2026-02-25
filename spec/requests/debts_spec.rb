require 'rails_helper'

RSpec.describe "Debts", type: :request do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123', monthly_income: 10000) }
  let(:debt) { user.debts.create!(lender_name: 'Bayport', principal_amount: 50000, monthly_payment: 2000, status: 'active') }
  
  before do
    sign_in user
  end
  
  describe "GET /index" do
    it "returns http success" do
      get debts_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get new_debt_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "creates a new debt" do
      expect {
        post debts_path, params: { debt: { lender_name: 'Madison', principal_amount: 30000, monthly_payment: 1500, status: 'active' } }
      }.to change(Debt, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get debt_path(debt)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get edit_debt_path(debt)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /update" do
    it "updates the debt" do
      patch debt_path(debt), params: { debt: { monthly_payment: 2500 } }
      expect(response).to have_http_status(:redirect)
      expect(debt.reload.monthly_payment).to eq(2500)
    end
  end

  describe "DELETE /destroy" do
    it "destroys the debt" do
      debt # create the debt
      expect {
        delete debt_path(debt)
      }.to change(Debt, :count).by(-1)
      expect(response).to have_http_status(:redirect)
    end
  end
end
