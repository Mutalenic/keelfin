class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :plan_name, null: false, default: 'free'
      t.string :status, null: false, default: 'active'
      t.datetime :start_date, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :end_date
      t.decimal :amount, precision: 10, scale: 2, default: 0.0
      t.jsonb :features, null: false, default: {}

      t.timestamps
    end
    
    add_index :subscriptions, :plan_name
    add_index :subscriptions, :status
  end
end
