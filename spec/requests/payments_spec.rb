require 'rails_helper'

RSpec.describe "Payments", type: :request do
  let(:user)     { create(:user) }
  let!(:category) { create(:category, user: user) }
  let!(:payment)  { create(:payment, user: user, category: category) }

  before { sign_in user }

  describe "GET /categories/:category_id/payments" do
    it "returns http success" do
      get category_payments_path(category)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /categories/:category_id/payments/new" do
    it "returns http success" do
      get new_category_payment_path(category)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /categories/:category_id/payments" do
    let(:valid_params) do
      { payment: { name: "Shoprite run", amount: 250, payment_method: "cash" } }
    end

    it "creates a payment and redirects" do
      expect {
        post category_payments_path(category), params: valid_params
      }.to change(Payment, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    it "renders new on invalid params" do
      post category_payments_path(category), params: { payment: { name: "", amount: -1 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /categories/:category_id/payments/:id" do
    it "updates the payment and redirects" do
      patch category_payment_path(category, payment),
            params: { payment: { name: "Updated name" } }
      expect(response).to have_http_status(:redirect)
      expect(payment.reload.name).to eq("Updated name")
    end
  end

  describe "DELETE /categories/:category_id/payments/:id" do
    it "destroys the payment and redirects" do
      expect {
        delete category_payment_path(category, payment)
      }.to change(Payment, :count).by(-1)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "authorization: other user's category returns redirect" do
    let(:other_user)     { create(:user) }

    before { sign_in other_user }

    it "redirects when category doesn't belong to signed-in user" do
      # set_category rescues RecordNotFound and redirects to categories_path
      get category_payments_path(category)
      expect(response).to have_http_status(:redirect)
    end
  end
end
