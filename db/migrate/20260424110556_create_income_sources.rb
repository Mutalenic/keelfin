class CreateIncomeSources < ActiveRecord::Migration[7.2]
  def change
    create_table :income_sources do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false, default: 0.0
      t.string :frequency, null: false, default: 'monthly'
      t.boolean :active, null: false, default: true
      t.text :notes

      t.timestamps
    end
    add_index :income_sources, [:user_id, :active]
    add_index :income_sources, :frequency
  end
end
