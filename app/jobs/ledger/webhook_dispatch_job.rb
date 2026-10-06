module Ledger
  # Asynchronously delivers signed webhook notifications for a posted transaction.
  # This job is always enqueued by TransactionProcessor after a successful post —
  # it is never called on the synchronous API request path.
  class WebhookDispatchJob < ApplicationJob
    queue_as :webhooks

    # Retry up to 3 times with Sidekiq's default exponential backoff.
    # After exhausting retries the job moves to the dead-job set.
    sidekiq_options retry: 3, dead: true

    def perform(transaction_id)
      txn = Ledger::Transaction.find(transaction_id)

      # Guard: only dispatch for posted transactions.
      unless txn.posted?
        Rails.logger.warn("[Ledger::WebhookDispatchJob] txn #{transaction_id} is #{txn.status}, skipping")
        return
      end

      Ledger::WebhookDispatcher.call(txn)
    end
  end
end
