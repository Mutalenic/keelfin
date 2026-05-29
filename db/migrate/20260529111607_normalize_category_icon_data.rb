class NormalizeCategoryIconData < ActiveRecord::Migration[7.2]
  def up
    # Normalize icon_name field to ensure all icons have fa-solid prefix
    Category.where.not(icon_name: nil).where.not(icon_name: '').find_each do |category|
      unless category.icon_name.start_with?('fa-solid ')
        # Remove any existing prefix and add fa-solid
        clean_icon = category.icon_name.sub(/^fa-/, '')
        category.update!(icon_name: "fa-solid fa-#{clean_icon}")
      end
    end
  end

  def down
    # Remove fa-solid prefix from icon_name field
    Category.where.not(icon_name: nil).where.not(icon_name: '').find_each do |category|
      if category.icon_name.start_with?('fa-solid ')
        category.update!(icon_name: category.icon_name.sub(/^fa-solid /, ''))
      end
    end
  end
end
