module Api
  module V1
    class AuditLogsController < BaseController
      ENTRIES_PER_PAGE = 50

      def index
        page = [params.fetch(:page, 1).to_i, 1].max
        per_page = [params.fetch(:per, ENTRIES_PER_PAGE).to_i, 200].min
        offset = (page - 1) * per_page

        logs = current_user
          .ledger_audit_logs
          .includes(:account, :ledger_transaction)
          .order(created_at: :desc)
          .limit(per_page)
          .offset(offset)

        render json: {
          page: page,
          per: per_page,
          audit_logs: logs.map { |l| serialize_log(l) }
        }
      end

      private

      def serialize_log(log)
        {
          id: log.id,
          event_type: log.event_type,
          account_id: log.account_id,
          account_name: log.account&.name,
          transaction_id: log.transaction_id,
          balance_before_ngwee: log.balance_before_ngwee,
          balance_after_ngwee: log.balance_after_ngwee,
          balance_delta_ngwee: log.balance_delta_ngwee,
          currency: log.currency,
          metadata: log.metadata,
          created_at: log.created_at.iso8601
        }
      end
    end
  end
end
