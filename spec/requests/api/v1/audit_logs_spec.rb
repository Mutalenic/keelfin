require 'rails_helper'

RSpec.describe 'Api::V1::AuditLogs', type: :request do
  let(:user) { create(:user) }
  let(:wallet) { create(:ledger_account, :asset, user: user) }
  let(:equity) { create(:ledger_account, :equity, user: user) }

  def auth_headers
    post '/api/v1/auth/sign_in',
         params: { user: { email: user.email, password: 'password123' } },
         as: :json
    { 'Authorization' => response.headers['Authorization'] }
  end

  def post_transaction
    Ledger::TransactionProcessor.call(
      user: user,
      description: 'Fund wallet',
      idempotency_key: SecureRandom.uuid,
      entries: [
        { account: wallet, direction: 'debit', amount_ngwee: 5000 },
        { account: equity, direction: 'credit', amount_ngwee: 5000 }
      ]
    )
  end

  describe 'GET /api/v1/audit_logs' do
    it 'returns 401 without a JWT token' do
      get '/api/v1/audit_logs'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns audit logs in descending order' do
      post_transaction
      post_transaction

      get '/api/v1/audit_logs', headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['audit_logs']).not_to be_empty

      timestamps = body['audit_logs'].pluck('created_at')
      expect(timestamps).to eq(timestamps.sort.reverse)
    end

    it 'returns balance_before, balance_after, and balance_delta' do
      post_transaction

      get '/api/v1/audit_logs', headers: auth_headers

      log = response.parsed_body['audit_logs'].first
      expect(log.keys).to include('balance_before_ngwee', 'balance_after_ngwee', 'balance_delta_ngwee')
    end

    it 'does not expose another user\'s audit logs' do
      other = create(:user)
      other_wallet = create(:ledger_account, :asset, user: other)
      other_equity = create(:ledger_account, :equity, user: other)
      Ledger::TransactionProcessor.call(
        user: other,
        description: 'Other user txn',
        idempotency_key: SecureRandom.uuid,
        entries: [
          { account: other_wallet, direction: 'debit', amount_ngwee: 1000 },
          { account: other_equity, direction: 'credit', amount_ngwee: 1000 }
        ]
      )

      get '/api/v1/audit_logs', headers: auth_headers

      body = response.parsed_body
      # Our user has no transactions; other user's logs must not appear
      user_log_ids = body['audit_logs'].pluck('id')
      other_log_ids = Ledger::AuditLog.where(user: other).pluck(:id)
      expect(user_log_ids & other_log_ids).to be_empty
    end
  end
end
