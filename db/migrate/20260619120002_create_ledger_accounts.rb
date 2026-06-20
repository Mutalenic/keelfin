class CreateLedgerAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :ledger_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :account_type, null: false # asset, liability, equity, income, expense
      t.string :currency, null: false, default: 'ZMW'
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :ledger_accounts, [:user_id, :active]
  end
end
