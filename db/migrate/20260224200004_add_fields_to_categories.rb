class AddFieldsToCategories < ActiveRecord::Migration[7.2]
  def up
    # Add new columns
    add_column :categories, :description, :text
    add_column :categories, :color, :string, default: '#3778c2'
    add_column :categories, :icon_name, :string
    add_column :categories, :category_type, :string, default: 'variable'
    
    # Handle existing duplicate categories
    duplicates = execute(<<-SQL
      SELECT name, user_id, COUNT(*)
      FROM categories
      GROUP BY name, user_id
      HAVING COUNT(*) > 1
    SQL
    ).to_a
    
    duplicates.each do |duplicate|
      name = duplicate['name']
      user_id = duplicate['user_id']
      
      # Get all duplicates except the first one
      dupe_ids = execute(<<-SQL
        SELECT id FROM categories
        WHERE name = '#{name}' AND user_id = #{user_id}
        ORDER BY created_at
        OFFSET 1
      SQL
      ).to_a.map { |r| r['id'] }
      
      # Update duplicate names to make them unique
      dupe_ids.each_with_index do |id, index|
        new_name = "#{name} (#{index + 1})"
        execute("UPDATE categories SET name = '#{new_name}' WHERE id = #{id}")
      end
    end
    
    # Add uniqueness index for category names per user
    add_index :categories, [:name, :user_id], unique: true
  end
  
  def down
    remove_index :categories, [:name, :user_id]
    remove_column :categories, :category_type
    remove_column :categories, :icon_name
    remove_column :categories, :color
    remove_column :categories, :description
  end
end
