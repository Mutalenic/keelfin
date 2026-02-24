class CreateBnnbDatas < ActiveRecord::Migration[7.2]
  def change
    create_table :bnnb_datas do |t|
      t.date :month, null: false
      t.string :location, default: 'Lusaka'
      t.decimal :total_basket, precision: 10, scale: 2, null: false
      t.decimal :food_basket, precision: 10, scale: 2, null: false
      t.decimal :non_food_basket, precision: 10, scale: 2, null: false
      t.jsonb :item_breakdown, default: {}

      t.timestamps
    end
    
    add_index :bnnb_datas, [:month, :location], unique: true
  end
end
