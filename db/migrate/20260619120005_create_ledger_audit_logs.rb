class CreateLedgerAuditLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :ledger_audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :transaction, foreign_key: { to_table: :ledger_transactions }
      t.references :account, foreign_key: { to_table: :ledger_accounts }
      t.string :event_type, null: false # transaction_posted, transaction_failed, account_created
      t.bigint :balance_before_ngwee
      t.bigint :balance_after_ngwee
      t.string :currency, default: 'ZMW'
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :ledger_audit_logs, [:user_id, :created_at]
  end
end
