class CreateBudgets < ActiveRecord::Migration[7.2]
  def change
    create_table :budgets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.decimal :monthly_limit, precision: 10, scale: 2, null: false
      t.date :start_date
      t.date :end_date
      t.boolean :inflation_adjusted, default: false

      t.timestamps
    end
    
    add_index :budgets, [:user_id, :category_id, :start_date]
  end
end
