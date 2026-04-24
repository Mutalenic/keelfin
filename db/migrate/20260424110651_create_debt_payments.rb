class CreateDebtPayments < ActiveRecord::Migration[7.2]
  def change
    create_table :debt_payments do |t|
      t.references :debt, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :paid_on, null: false
      t.text :notes

      t.timestamps
    end
    add_index :debt_payments, [:debt_id, :paid_on]
  end
end
