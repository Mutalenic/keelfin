class AddBnnbMappingToCategories < ActiveRecord::Migration[7.2]
  def change
    add_column :categories, :bnnb_mapping, :string
  end
end
