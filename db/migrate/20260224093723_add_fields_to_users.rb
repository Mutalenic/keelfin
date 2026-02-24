class AddFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :monthly_income, :decimal, precision: 10, scale: 2
    add_column :users, :currency, :string, default: 'ZMW'
    add_column :users, :phone_number, :string
    add_column :users, :mtn_momo_number, :string
    add_column :users, :airtel_money_number, :string
    add_column :users, :two_factor_enabled, :boolean, default: false
    
    add_index :users, :phone_number
  end
end
