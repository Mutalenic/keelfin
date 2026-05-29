class NormalizeCategoryIconData < ActiveRecord::Migration[7.2]
  class MigrationCategory < ActiveRecord::Base
    self.table_name = 'categories'
  end

  def up
    MigrationCategory.where.not(icon_name: nil).where.not(icon_name: '').find_each do |category|
      next if category.icon_name.start_with?('fa-solid ')

      icon_name = category.icon_name.sub(/^fa-(solid|regular|brands|light|thin|duotone)\s+fa-/, 'fa-').sub(/^fa-/, '')
      category.update_columns(icon_name: "fa-solid fa-#{icon_name}")
    end
  end

  def down
    MigrationCategory.where.not(icon_name: nil).where.not(icon_name: '').find_each do |category|
      next unless category.icon_name.start_with?('fa-solid ')

      category.update_columns(icon_name: category.icon_name.sub(/^fa-solid /, ''))
    end
  end
end
