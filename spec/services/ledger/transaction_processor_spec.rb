require 'rails_helper'

RSpec.describe Ledger::TransactionProcessor, type: :service do
  let(:user)    { create(:user) }
  let(:wallet)  { create(:ledger_account, :asset,   user: user, name: 'Wallet') }
  let(:savings) { create(:ledger_account, :asset,   user: user, name: 'Savings') }
  let(:expense) { create(:ledger_account, :expense, user: user, name: 'Groceries') }
  let(:equity)  { create(:ledger_account, :equity,  user: user, name: 'Equity') }

  # Seed wallet with ZMW 200 (20_000 cents)
  def fund_wallet(amount_cents = 20_000)
    Ledger::TransactionProcessor.call(
      user:            user,
      description:     'Initial funding',
      idempotency_key: "fund-#{SecureRandom.uuid}",
      entries: [
        { account: wallet, direction: 'debit',  amount_cents: amount_cents },
        { account: equity, direction: 'credit', amount_cents: amount_cents }
      ]
    )
  end

  describe '.call' do
    context 'with a valid balanced transfer' do
      before { fund_wallet }

      it 'posts the transaction and returns it' do
        txn = described_class.call(
          user:            user,
          description:     'Transfer to savings',
          idempotency_key: SecureRandom.uuid,
          entries: [
            { account: wallet,  direction: 'credit', amount_cents: 5000 },
            { account: savings, direction: 'debit',  amount_cents: 5000 }
          ]
        )

        expect(txn).to be_a(Ledger::Transaction)
        expect(txn.status).to eq('posted')
        expect(txn.entries.count).to eq(2)
      end

      it 'updates account balances correctly' do
        expect { fund_wallet }.to change { wallet.reload.balance_cents }.by(20_000)
      end

      it 'creates AuditLog entries for each entry' do
        expect {
          described_class.call(
            user:            user,
            description:     'Spend on groceries',
            idempotency_key: SecureRandom.uuid,
            entries: [
              { account: wallet,  direction: 'credit', amount_cents: 3000 },
              { account: expense, direction: 'debit',  amount_cents: 3000 }
            ]
          )
        }.to change { Ledger::AuditLog.count }.by(2)
      end

      it 'enqueues WebhookDispatchJob after posting' do
        expect {
          described_class.call(
            user:            user,
            description:     'Spend on groceries',
            idempotency_key: SecureRandom.uuid,
            entries: [
              { account: wallet,  direction: 'credit', amount_cents: 1000 },
              { account: expense, direction: 'debit',  amount_cents: 1000 }
            ]
          )
        }.to have_enqueued_job(Ledger::WebhookDispatchJob)
      end
    end

    context 'idempotency' do
      before { fund_wallet }

      it 'returns the existing transaction when the idempotency key already exists' do
        key = SecureRandom.uuid
        entries = [
          { account: wallet,  direction: 'credit', amount_cents: 2000 },
          { account: savings, direction: 'debit',  amount_cents: 2000 }
        ]

        first  = described_class.call(user: user, description: 'Txn', idempotency_key: key, entries: entries)
        second = described_class.call(user: user, description: 'Txn', idempotency_key: key, entries: entries)

        expect(first.id).to eq(second.id)
        expect(Ledger::Transaction.where(idempotency_key: key).count).to eq(1)
      end
    end

    context 'with imbalanced entries' do
      it 'raises ImbalancedEntries without persisting anything' do
        expect {
          described_class.call(
            user:            user,
            description:     'Bad txn',
            idempotency_key: SecureRandom.uuid,
            entries: [
              { account: wallet,  direction: 'debit',  amount_cents: 5000 },
              { account: savings, direction: 'credit', amount_cents: 3000 }
            ]
          )
        }.to raise_error(Ledger::TransactionProcessor::ImbalancedEntries)
          .and change { Ledger::Transaction.count }.by(0)
      end
    end

    context 'with insufficient funds (credit from asset account)' do
      it 'raises InsufficientFunds when the asset balance is too low' do
        # wallet starts at 0 cents — any credit should fail
        expect {
          described_class.call(
            user:            user,
            description:     'Overdraft attempt',
            idempotency_key: SecureRandom.uuid,
            entries: [
              { account: wallet,  direction: 'credit', amount_cents: 500 },
              { account: expense, direction: 'debit',  amount_cents: 500 }
            ]
          )
        }.to raise_error(Ledger::TransactionProcessor::InsufficientFunds)
      end

      it 'does NOT raise when debiting an asset (that increases balance)' do
        expect {
          described_class.call(
            user:            user,
            description:     'Fund from equity',
            idempotency_key: SecureRandom.uuid,
            entries: [
              { account: wallet, direction: 'debit',  amount_cents: 5000 },
              { account: equity, direction: 'credit', amount_cents: 5000 }
            ]
          )
        }.not_to raise_error
      end
    end
  end
end
