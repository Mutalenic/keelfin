module Ledger
  # An async entry point for deferred or bulk transaction submission.
  # This job is NOT used by the API controller hot path (which posts synchronously).
  # It exists as a tested, functional async path — e.g. for import pipelines or
  # scheduled batch postings — and as a showcase of queue-based ledger architecture.
  #
  # Because TransactionProcessor checks the idempotency key first, this job is
  # safe to enqueue multiple times for the same payload without double-posting.
  class TransactionProcessorJob < ApplicationJob
    queue_as :transactions

    sidekiq_options retry: 3, dead: true, backtrace: true

    # rubocop:disable Metrics/ParameterLists
    def perform(user_id:, description:, idempotency_key:, entries:,
                metadata: {}, transaction_type: 'transfer')
      user = User.find(user_id)

      # Deserialise entries: each element is a hash with string keys from the queue.
      resolved_entries = entries.map do |e|
        account = Ledger::Account.find(e['account_id'])
        {
          account: account,
          direction: e['direction'],
          amount_ngwee: e['amount_ngwee'].to_i,
          currency: e.fetch('currency', account.currency)
        }
      end

      Ledger::TransactionProcessor.call(
        user: user,
        description: description,
        idempotency_key: idempotency_key,
        entries: resolved_entries,
        metadata: metadata,
        transaction_type: transaction_type
      )
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
