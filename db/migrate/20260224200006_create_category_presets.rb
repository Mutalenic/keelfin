class CreateCategoryPresets < ActiveRecord::Migration[7.2]
  def change
    create_table :category_presets do |t|
      t.string :name, null: false
      t.string :icon
      t.string :icon_name
      t.string :color, default: '#3778c2'
      t.string :category_type, null: false
      t.text :description
      t.boolean :is_default, default: false
      t.integer :display_order, default: 0

      t.timestamps
    end
    
    add_index :category_presets, :name, unique: true
    add_index :category_presets, :category_type
  end
end
