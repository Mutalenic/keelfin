class AddFieldsToPayments < ActiveRecord::Migration[7.2]
  def change
    add_column :payments, :payment_method, :string
    add_column :payments, :transaction_reference, :string
    add_column :payments, :is_essential, :boolean, default: true
    add_column :payments, :notes, :text
    
    add_index :payments, :created_at
    add_index :payments, :amount
    add_index :payments, [:user_id, :created_at]
  end
end
