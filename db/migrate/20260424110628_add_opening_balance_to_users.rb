class AddOpeningBalanceToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :opening_balance, :decimal, precision: 12, scale: 2, default: 0.0
    add_column :users, :balance_as_of, :date
  end
end
