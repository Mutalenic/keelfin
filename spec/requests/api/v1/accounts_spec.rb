require 'rails_helper'

RSpec.describe 'Api::V1::Accounts', type: :request do
  let(:user) { create(:user) }
  let(:other) { create(:user) }

  def auth_headers(auth_user = user)
    post '/api/v1/auth/sign_in',
         params: { user: { email: auth_user.email, password: 'password123' } },
         as: :json
    { 'Authorization' => response.headers['Authorization'] }
  end

  describe 'GET /api/v1/accounts' do
    it 'returns 401 without a JWT token' do
      get '/api/v1/accounts'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns only the current user\'s active accounts' do
      create(:ledger_account, user: user, name: 'My Wallet')
      create(:ledger_account, user: other, name: 'Other Wallet')

      get '/api/v1/accounts', headers: auth_headers

      expect(response).to have_http_status(:ok)
      names = response.parsed_body.pluck('name')
      expect(names).to include('My Wallet')
      expect(names).not_to include('Other Wallet')
    end
  end

  describe 'POST /api/v1/accounts' do
    it 'creates an account and returns 201 with audit log' do
      expect do
        post '/api/v1/accounts',
             params: { account: { name: 'Savings', account_type: 'asset', currency: 'ZMW' } },
             as: :json,
             headers: auth_headers
      end.to change(Ledger::Account, :count).by(1)
        .and change(Ledger::AuditLog, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['name']).to eq('Savings')
    end

    it 'returns 422 for invalid account type' do
      post '/api/v1/accounts',
           params: { account: { name: 'Bad', account_type: 'invalid' } },
           as: :json,
           headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/accounts/:id/balance' do
    it 'returns the current balance in ngwee' do
      account = create(:ledger_account, :asset, user: user, name: 'Test')

      get "/api/v1/accounts/#{account.id}/balance", headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to include('balance_ngwee', 'currency', 'account_id')
    end

    it 'returns 404 for another user\'s account' do
      other_account = create(:ledger_account, user: other)

      get "/api/v1/accounts/#{other_account.id}/balance", headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
