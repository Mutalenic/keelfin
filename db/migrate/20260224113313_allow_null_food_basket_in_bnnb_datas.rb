class AllowNullFoodBasketInBnnbDatas < ActiveRecord::Migration[7.2]
  def change
    change_column_null :bnnb_datas, :food_basket, true
    change_column_null :bnnb_datas, :non_food_basket, true
    change_column_null :bnnb_datas, :total_basket, true
  end
end
