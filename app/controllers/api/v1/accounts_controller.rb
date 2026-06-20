module Api
  module V1
    class AccountsController < BaseController
      def index
        accounts = current_user.ledger_accounts.active.order(:name)
        render json: accounts.map { |a| serialize_account(a) }
      end

      def show
        render json: serialize_account(account)
      end

      def create
        acct = current_user.ledger_accounts.create!(account_params)
        Ledger::AuditLog.create!(
          user: current_user,
          account: acct,
          event_type: 'account_created',
          currency: acct.currency,
          metadata: { name: acct.name, account_type: acct.account_type }
        )
        render json: serialize_account(acct), status: :created
      end

      def balance
        render json: {
          account_id: account.id,
          balance_ngwee: account.balance_ngwee,
          currency: account.currency
        }
      end

      private

      def account
        @account ||= current_user.ledger_accounts.find(params[:id])
      end

      def account_params
        params.require(:account).permit(:name, :account_type, :currency)
      end

      def serialize_account(acct)
        {
          id: acct.id,
          name: acct.name,
          account_type: acct.account_type,
          currency: acct.currency,
          active: acct.active,
          balance_ngwee: acct.balance_ngwee,
          created_at: acct.created_at.iso8601
        }
      end
    end
  end
end
