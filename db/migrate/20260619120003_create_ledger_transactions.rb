class CreateLedgerTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :ledger_transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :description, null: false
      t.string :status, null: false, default: 'pending' # pending, processing, posted, failed
      t.string :idempotency_key, null: false
      t.string :transaction_type, null: false, default: 'transfer'
      t.text :metadata # JSON string
      t.timestamps
    end

    add_index :ledger_transactions, :idempotency_key, unique: true
    add_index :ledger_transactions, [:user_id, :status]
  end
end
