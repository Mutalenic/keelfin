class CreateEconomicIndicators < ActiveRecord::Migration[7.2]
  def change
    create_table :economic_indicators do |t|
      t.date :date, null: false
      t.decimal :inflation_rate, precision: 5, scale: 2
      t.decimal :usd_zmw_rate, precision: 8, scale: 4
      t.string :source

      t.timestamps
    end
    
    add_index :economic_indicators, :date, unique: true
  end
end
