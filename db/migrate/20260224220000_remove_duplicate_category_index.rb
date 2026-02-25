class RemoveDuplicateCategoryIndex < ActiveRecord::Migration[7.2]
  def change
    # Remove the duplicate unique index on categories table
    # Keep index_categories_on_name_and_user_id, remove unique_categories_per_user
    remove_index :categories, name: "unique_categories_per_user", if_exists: true
  end
end
