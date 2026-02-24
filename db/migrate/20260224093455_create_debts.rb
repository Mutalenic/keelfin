class CreateDebts < ActiveRecord::Migration[7.2]
  def change
    create_table :debts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :lender_name, null: false
      t.decimal :principal_amount, precision: 12, scale: 2, null: false
      t.decimal :interest_rate, precision: 5, scale: 2
      t.decimal :monthly_payment, precision: 10, scale: 2
      t.integer :term
      t.string :status, default: 'active'
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
    
    add_index :debts, [:user_id, :status]
  end
end
