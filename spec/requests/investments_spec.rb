require 'rails_helper'

RSpec.describe "Investments", type: :request do
  let(:user)       { create(:user) }
  let!(:investment) { create(:investment, user: user) }

  before { sign_in user }

  describe "GET /investments" do
    it "returns http success" do
      get investments_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /investments/new" do
    it "returns http success" do
      get new_investment_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /investments" do
    let(:valid_params) do
      { investment: {
          name: "ZANACO Shares",
          investment_type: "stocks",
          initial_amount: 5_000,
          current_value: 5_000,
          start_date: Date.current,
          risk_level: 3
        } }
    end

    it "creates an investment and redirects" do
      expect {
        post investments_path, params: valid_params
      }.to change(Investment, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    it "renders new on invalid params" do
      post investments_path, params: { investment: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /investments/:id" do
    it "returns http success" do
      get investment_path(investment)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /investments/:id/edit" do
    it "returns http success" do
      get edit_investment_path(investment)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /investments/:id" do
    it "updates the investment and redirects" do
      patch investment_path(investment), params: { investment: { name: "Renamed Fund" } }
      expect(response).to have_http_status(:redirect)
      expect(investment.reload.name).to eq("Renamed Fund")
    end
  end

  describe "PATCH /investments/:id/update_value" do
    it "updates current value and redirects" do
      patch update_value_investment_path(investment),
            params: { current_value: 15_000 }
      expect(response).to have_http_status(:redirect)
      expect(investment.reload.current_value.to_f).to eq(15_000.0)
    end
  end

  describe "DELETE /investments/:id" do
    it "destroys the investment and redirects" do
      expect {
        delete investment_path(investment)
      }.to change(Investment, :count).by(-1)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "authorization: other user cannot access" do
    let(:other_user) { create(:user) }

    before { sign_in other_user }

    it "redirects away from another user's investment" do
      get investment_path(investment)
      expect(response).to have_http_status(:redirect)
    end
  end
end
