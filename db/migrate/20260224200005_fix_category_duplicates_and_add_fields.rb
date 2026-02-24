class FixCategoryDuplicatesAndAddFields < ActiveRecord::Migration[7.2]
  def up
    # Add new columns
    add_column :categories, :description, :text unless column_exists?(:categories, :description)
    add_column :categories, :color, :string, default: '#3778c2' unless column_exists?(:categories, :color)
    add_column :categories, :icon_name, :string unless column_exists?(:categories, :icon_name)
    add_column :categories, :category_type, :string, default: 'variable' unless column_exists?(:categories, :category_type)
    
    # Find and fix duplicate categories
    execute(<<-SQL)
      UPDATE categories c1
      SET name = c1.name || ' ' || c1.id
      FROM (
        SELECT MIN(id) as min_id, name, user_id
        FROM categories
        GROUP BY name, user_id
        HAVING COUNT(*) > 1
      ) c2
      WHERE c1.name = c2.name 
        AND c1.user_id = c2.user_id 
        AND c1.id != c2.min_id;
    SQL
    
    # Now it's safe to add the unique index
    add_index :categories, [:name, :user_id], unique: true, name: 'unique_categories_per_user'
  end
  
  def down
    remove_index :categories, name: 'unique_categories_per_user' if index_exists?(:categories, [:name, :user_id], name: 'unique_categories_per_user')
    remove_column :categories, :category_type if column_exists?(:categories, :category_type)
    remove_column :categories, :icon_name if column_exists?(:categories, :icon_name)
    remove_column :categories, :color if column_exists?(:categories, :color)
    remove_column :categories, :description if column_exists?(:categories, :description)
  end
  
  private
  
  def column_exists?(table, column)
    ActiveRecord::Base.connection.column_exists?(table, column)
  end
  
  def index_exists?(table, columns, options = {})
    ActiveRecord::Base.connection.index_exists?(table, columns, options)
  end
end
