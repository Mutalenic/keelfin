require 'rails_helper'

RSpec.describe 'Dashboards', type: :request do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123') }

  before do
    sign_in user
  end

  describe 'GET /index' do
    it 'returns http success' do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end
end
