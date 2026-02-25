class CreateInvestmentTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :investment_transactions do |t|
      t.references :investment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :transaction_date, null: false
      t.string :transaction_type, null: false
      t.string :description
      t.string :reference_number
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    
    add_index :investment_transactions, [:investment_id, :transaction_type]
    add_index :investment_transactions, :transaction_date
  end
end
