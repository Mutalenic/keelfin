class CreateLedgerEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :ledger_entries do |t|
      t.references :transaction, null: false, foreign_key: { to_table: :ledger_transactions }
      t.references :account, null: false, foreign_key: { to_table: :ledger_accounts }
      t.string :direction, null: false # debit, credit
      t.bigint :amount_ngwee, null: false # money stored as integer ngwee
      t.string :currency, null: false, default: 'ZMW'
      t.timestamps
    end

    add_index :ledger_entries, [:account_id, :direction]
  end
end
