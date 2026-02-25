class CreateFinancialGoals < ActiveRecord::Migration[7.2]
  def change
    create_table :financial_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, foreign_key: true
      t.string :name, null: false
      t.string :description
      t.decimal :target_amount, precision: 12, scale: 2, null: false
      t.decimal :current_amount, precision: 12, scale: 2, default: 0
      t.date :start_date, null: false
      t.date :target_date, null: false
      t.date :completion_date
      t.string :goal_type, null: false
      t.boolean :completed, default: false
      t.boolean :recurring, default: false
      t.string :recurrence_period
      t.jsonb :milestones, default: {}
      t.string :priority, default: 'medium'

      t.timestamps
    end
    
    add_index :financial_goals, [:user_id, :goal_type]
    add_index :financial_goals, [:user_id, :completed]
  end
end
