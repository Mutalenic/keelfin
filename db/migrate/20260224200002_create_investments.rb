class CreateInvestments < ActiveRecord::Migration[7.2]
  def change
    create_table :investments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :investment_type, null: false
      t.decimal :initial_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :current_value, precision: 12, scale: 2, null: false, default: 0
      t.decimal :target_value, precision: 12, scale: 2
      t.date :start_date
      t.date :target_date
      t.date :last_updated
      t.integer :risk_level
      t.string :institution
      t.string :account_number
      t.boolean :active, default: true
      t.text :notes
      t.jsonb :value_history, default: []
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    
    add_index :investments, [:user_id, :investment_type]
    add_index :investments, [:user_id, :active]
  end
end
