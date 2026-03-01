require 'rails_helper'

RSpec.describe "Categories", type: :request do
  let(:user)     { create(:user) }
  let!(:category) { create(:category, user: user) }

  before { sign_in user }

  describe "GET /categories" do
    it "returns http success" do
      get categories_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /categories/new" do
    it "returns http success" do
      get new_category_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /categories" do
    let(:valid_params) do
      { category: { name: "Transport", icon: "fa-solid fa-car",
                    color: "#607D8B", category_type: "variable" } }
    end

    it "creates a new category and redirects" do
      expect {
        post categories_path, params: valid_params
      }.to change(Category, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    it "renders new on invalid params" do
      post categories_path, params: { category: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /categories/:id" do
    it "returns http success" do
      get category_path(category)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /categories/:id/edit" do
    it "returns http success" do
      get edit_category_path(category)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /categories/:id" do
    it "updates the category and redirects" do
      patch category_path(category), params: { category: { name: "Renamed" } }
      expect(response).to have_http_status(:redirect)
      expect(category.reload.name).to eq("Renamed")
    end
  end

  describe "DELETE /categories/:id" do
    it "destroys the category and redirects" do
      expect {
        delete category_path(category)
      }.to change(Category, :count).by(-1)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "authorization: other user cannot access" do
    let(:other_user) { create(:user) }

    before { sign_in other_user }

    it "redirects away from another user's category" do
      get category_path(category)
      expect(response).to have_http_status(:redirect)
    end
  end
end
