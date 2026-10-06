module Ledger
  # TransactionProcessor is the single, authoritative write path for all ledger
  # transactions. It runs synchronously inside a database transaction with
  # per-account row locking so that double-spend is impossible under concurrency.
  #
  # Usage:
  #   result = Ledger::TransactionProcessor.call(
  #     user:             current_user,
  #     description:      "Transfer to savings",
  #     idempotency_key:  params[:idempotency_key],
  #     entries: [
  #       { account: checking_account, direction: 'credit', amount_ngwee: 5000 },
  #       { account: savings_account,  direction: 'debit',  amount_ngwee: 5000 }
  #     ]
  #   )
  class TransactionProcessor
    class ImbalancedEntries < StandardError; end
    class InsufficientFunds < StandardError; end

    def self.call(**)
      new(**).call
    end

    # rubocop:disable Metrics/ParameterLists
    def initialize(user:, description:, idempotency_key:, entries:,
                   metadata: {}, transaction_type: 'transfer')
      @user = user
      @description = description
      @idempotency_key = idempotency_key
      @entries = entries
      @metadata = metadata
      @transaction_type = transaction_type
    end
    # rubocop:enable Metrics/ParameterLists

    def call
      # Idempotency guard: return any existing record for this key immediately.
      # Terminal states (posted / failed) are final; non-terminal means a prior
      # attempt is still in flight or was interrupted — do not re-create.
      existing = Ledger::Transaction.find_by(user: @user, idempotency_key: @idempotency_key)
      return existing if existing

      validate_entries_balance!

      # rubocop:disable Metrics/BlockLength
      ActiveRecord::Base.transaction do
        txn = Ledger::Transaction.create!(
          user: @user,
          description: @description,
          idempotency_key: @idempotency_key,
          status: 'processing',
          transaction_type: @transaction_type,
          metadata: @metadata.to_json
        )

        @entries.each do |attrs|
          # Lock the account row for the duration of this DB transaction to
          # prevent concurrent transactions from reading a stale balance.
          account = attrs[:account].lock!

          balance_before = account.balance_ngwee

          # CORRECTED funds check: money leaves an asset account on a CREDIT
          # (credit-normal accounts like liabilities/equity/income empty on debit).
          if account.account_type == 'asset' && attrs[:direction] == 'credit' && (balance_before < attrs[:amount_ngwee])
            raise InsufficientFunds,
                  "Account '#{account.name}' has insufficient funds " \
                  "(balance: #{balance_before} ngwee, required: #{attrs[:amount_ngwee]} ngwee)"
          end

          txn.entries.create!(
            account: account,
            direction: attrs[:direction],
            amount_ngwee: attrs[:amount_ngwee],
            currency: attrs[:currency] || account.currency
          )

          balance_after = account.reload.balance_ngwee

          Ledger::AuditLog.create!(
            user: @user,
            ledger_transaction: txn,
            account: account,
            event_type: 'transaction_posted',
            balance_before_ngwee: balance_before,
            balance_after_ngwee: balance_after,
            currency: account.currency,
            metadata: {
              direction: attrs[:direction],
              amount_ngwee: attrs[:amount_ngwee]
            }
          )
        end

        txn.update!(status: 'posted')

        # Fan out webhook delivery asynchronously — never on the hot posting path.
        Ledger::WebhookDispatchJob.perform_later(txn.id)

        txn
      end
      # rubocop:enable Metrics/BlockLength
    end

    private

    def validate_entries_balance!
      net = @entries.sum do |e|
        e[:direction] == 'debit' ? e[:amount_ngwee] : -e[:amount_ngwee]
      end
      return if net.zero?

      raise ImbalancedEntries,
            "Entries do not balance: net #{net} ngwee " \
            '(all debits must equal all credits)'
    end
  end
end
