require 'rails_helper'

RSpec.describe 'Api::V1::LedgerTransactions', type: :request do
  let(:user) { create(:user) }
  let(:wallet) { create(:ledger_account, :asset, user: user, name: 'Wallet') }
  let(:equity) { create(:ledger_account, :equity, user: user, name: 'Equity') }

  def auth_headers
    post '/api/v1/auth/sign_in',
         params: { user: { email: user.email, password: 'password123' } },
         as: :json
    { 'Authorization' => response.headers['Authorization'] }
  end

  # Pre-fund wallet so asset credit tests pass the balance check.
  def fund_wallet(amount_ngwee = 20_000)
    Ledger::TransactionProcessor.call(
      user: user,
      description: 'Seed funding',
      idempotency_key: "seed-#{SecureRandom.uuid}",
      entries: [
        { account: wallet, direction: 'debit', amount_ngwee: amount_ngwee },
        { account: equity, direction: 'credit', amount_ngwee: amount_ngwee }
      ]
    )
  end

  describe 'GET /api/v1/ledger_transactions' do
    it 'returns 401 without a JWT token' do
      get '/api/v1/ledger_transactions'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a paginated list of transactions in descending order' do
      fund_wallet
      get '/api/v1/ledger_transactions', headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['transactions']).to be_an(Array)
      # Most recent first
      timestamps = body['transactions'].pluck('created_at')
      expect(timestamps).to eq(timestamps.sort.reverse)
    end
  end

  describe 'POST /api/v1/ledger_transactions' do
    let(:expense) { create(:ledger_account, :expense, user: user, name: 'Groceries') }
    let(:headers) { auth_headers }

    before { fund_wallet }

    def txn_params(description:, idempotency_key:, entries:)
      {
        description: description,
        idempotency_key: idempotency_key,
        entries: entries
      }
    end

    it 'creates a posted transaction and returns 201' do
      post '/api/v1/ledger_transactions',
           params: txn_params(
             description: 'Buy groceries',
             idempotency_key: SecureRandom.uuid,
             entries: [
               { account_id: wallet.id, direction: 'credit', amount_ngwee: 3000 },
               { account_id: expense.id, direction: 'debit', amount_ngwee: 3000 }
             ]
           ),
           as: :json,
           headers: headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body['status']).to eq('posted')
      expect(body['entries'].count).to eq(2)
    end

    it 'returns 422 for imbalanced entries with a descriptive message' do
      post '/api/v1/ledger_transactions',
           params: txn_params(
             description: 'Imbalanced',
             idempotency_key: SecureRandom.uuid,
             entries: [
               { account_id: wallet.id, direction: 'credit', amount_ngwee: 5000 },
               { account_id: expense.id, direction: 'debit', amount_ngwee: 3000 }
             ]
           ),
           as: :json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to match(/balance/i)
    end

    it 'returns 422 for insufficient funds' do
      post '/api/v1/ledger_transactions',
           params: txn_params(
             description: 'Overdraft',
             idempotency_key: SecureRandom.uuid,
             entries: [
               { account_id: wallet.id, direction: 'credit', amount_ngwee: 999_999 },
               { account_id: expense.id, direction: 'debit', amount_ngwee: 999_999 }
             ]
           ),
           as: :json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to match(/insufficient/i)
    end

    it 'is idempotent — returns same transaction on duplicate key' do
      key = SecureRandom.uuid
      params = txn_params(
        description: 'Idempotent spend',
        idempotency_key: key,
        entries: [
          { account_id: wallet.id, direction: 'credit', amount_ngwee: 1000 },
          { account_id: expense.id, direction: 'debit', amount_ngwee: 1000 }
        ]
      )

      post '/api/v1/ledger_transactions', params: params, as: :json, headers: headers
      id1 = response.parsed_body['id']

      post '/api/v1/ledger_transactions', params: params, as: :json, headers: headers
      id2 = response.parsed_body['id']

      expect(id1).to eq(id2)
    end
  end
end
