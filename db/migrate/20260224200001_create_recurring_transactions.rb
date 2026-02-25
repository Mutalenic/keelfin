class CreateRecurringTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :recurring_transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :frequency, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.date :next_occurrence
      t.date :last_occurrence
      t.boolean :active, default: true
      t.string :payment_method
      t.boolean :is_essential, default: true
      t.text :notes
      t.integer :occurrences_count, default: 0
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    
    add_index :recurring_transactions, [:user_id, :active]
    add_index :recurring_transactions, :next_occurrence
  end
end
