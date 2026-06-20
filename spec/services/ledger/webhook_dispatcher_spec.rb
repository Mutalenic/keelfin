require 'rails_helper'

RSpec.describe Ledger::WebhookDispatcher, type: :service do
  let(:user)     { create(:user) }
  let(:wallet)   { create(:ledger_account, :asset,  user: user) }
  let(:equity)   { create(:ledger_account, :equity, user: user) }
  let(:endpoint) { create(:ledger_webhook_endpoint, user: user) }
  let(:txn) do
    t = create(:ledger_transaction, :posted, user: user)
    create(:ledger_entry, ledger_transaction: t, account: wallet,  direction: 'debit',  amount_cents: 5000)
    create(:ledger_entry, ledger_transaction: t, account: equity,  direction: 'credit', amount_cents: 5000)
    t
  end

  describe '.call' do
    before { endpoint } # ensure endpoint exists before dispatching

    context 'when the endpoint responds with 200' do
      before do
        stub_request(:post, endpoint.url)
          .to_return(status: 200, body: '{"ok":true}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'marks the delivery as delivered' do
        described_class.call(txn)
        delivery = Ledger::WebhookDelivery.last
        expect(delivery.status).to eq('delivered')
        expect(delivery.http_status_code).to eq(200)
      end

      it 'sends the correct HMAC-SHA256 signature header' do
        described_class.call(txn)

        expect(WebMock).to have_requested(:post, endpoint.url)
          .with { |req|
            expected_sig = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', endpoint.secret, req.body)}"
            req.headers['X-Keelfine-Signature'] == expected_sig
          }
      end

      it 'increments the attempt_count' do
        described_class.call(txn)
        expect(Ledger::WebhookDelivery.last.attempt_count).to eq(1)
      end
    end

    context 'when the endpoint returns a non-2xx response' do
      before do
        stub_request(:post, endpoint.url).to_return(status: 500, body: 'Server Error')
      end

      it 'marks the delivery as failed' do
        # Disable faraday-retry in test to avoid 3x slow requests
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_raise(
          Faraday::ServerError.new('500')
        )
        described_class.call(txn)
        delivery = Ledger::WebhookDelivery.last
        expect(delivery.status).to eq('failed')
      end
    end

    context 'when the endpoint times out' do
      before do
        stub_request(:post, endpoint.url).to_timeout
      end

      it 'marks the delivery as failed with a timeout error message' do
        described_class.call(txn)
        delivery = Ledger::WebhookDelivery.last
        expect(delivery.status).to eq('failed')
        expect(delivery.response_body).to include('Faraday')
      end
    end
  end
end
