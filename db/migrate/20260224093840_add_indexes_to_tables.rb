class AddIndexesToTables < ActiveRecord::Migration[7.2]
  def change
    # Additional performance indexes for existing tables
    add_index :payments, :user_id unless index_exists?(:payments, :user_id)
    add_index :categories, :user_id unless index_exists?(:categories, :user_id)
    
    # Composite indexes for common queries
    add_index :payments, [:user_id, :category_id] unless index_exists?(:payments, [:user_id, :category_id])
  end
end
