module Api
  module V1
    class LedgerTransactionsController < BaseController
      ENTRIES_PER_PAGE = 25

      def index
        page = [params.fetch(:page, 1).to_i, 1].max
        per_page = [params.fetch(:per, ENTRIES_PER_PAGE).to_i, 100].min
        offset = (page - 1) * per_page

        txns = current_user
          .ledger_transactions
          .includes(entries: :account)
          .order(created_at: :desc)
          .limit(per_page)
          .offset(offset)

        render json: {
          page: page,
          per: per_page,
          transactions: txns.map { |t| serialize_transaction(t) }
        }
      end

      def show
        render json: serialize_transaction(ledger_transaction)
      end

      def create
        entries = build_entries_from_params

        txn = Ledger::TransactionProcessor.call(
          user: current_user,
          description: params.require(:description),
          idempotency_key: params[:idempotency_key].presence || SecureRandom.uuid,
          entries: entries,
          metadata: params[:metadata]&.to_unsafe_h || {},
          transaction_type: params.fetch(:transaction_type, 'transfer')
        )

        render json: serialize_transaction(txn), status: :created
      end

      private

      def ledger_transaction
        @ledger_transaction ||= current_user.ledger_transactions
          .includes(entries: :account)
          .find(params[:id])
      end

      def build_entries_from_params
        entries_param = params[:entries]
        raise ActionController::ParameterMissing, 'entries are required' if entries_param.blank?

        entries_param.map do |e|
          account = current_user.ledger_accounts.find(e[:account_id])
          {
            account: account,
            direction: e[:direction],
            amount_ngwee: e[:amount_ngwee].to_i,
            currency: e[:currency].presence || account.currency
          }
        end
      end

      def serialize_transaction(txn)
        {
          id: txn.id,
          description: txn.description,
          status: txn.status,
          transaction_type: txn.transaction_type,
          idempotency_key: txn.idempotency_key,
          metadata: txn.metadata_hash,
          created_at: txn.created_at.iso8601,
          entries: txn.entries.map { |e| serialize_entry(e) }
        }
      end

      def serialize_entry(entry)
        {
          id: entry.id,
          account_id: entry.account_id,
          account_name: entry.account.name,
          direction: entry.direction,
          amount_ngwee: entry.amount_ngwee,
          currency: entry.currency
        }
      end
    end
  end
end
