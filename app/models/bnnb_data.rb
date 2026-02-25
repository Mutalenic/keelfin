class BnnbData < ApplicationRecord
  self.table_name = 'bnnb_datas'
  validates :month, presence: true, uniqueness: { scope: :location }
  validates :total_basket, :food_basket, :non_food_basket, 
            numericality: { greater_than: 0 }, allow_nil: true
  
  scope :recent, -> { order(month: :desc).limit(12) }
  scope :for_location, ->(loc) { where(location: loc) }
  
  def self.latest(location = 'Lusaka')
    for_location(location).order(month: :desc).first
  end
  
  def self.compare_user_spending(user, month = Date.current.beginning_of_month)
    bnnb = where(month: month.beginning_of_month).first
    return nil unless bnnb
    return nil unless bnnb.food_basket.present?
    
    user_food = user.payments.joins(:category)
      .where('categories.name ILIKE ?', '%food%')
      .where('payments.created_at >= ? AND payments.created_at <= ?', month, month.end_of_month)
      .sum(:amount)
    
    {
      bnnb_food: bnnb.food_basket,
      user_food: user_food,
      difference: user_food - bnnb.food_basket,
      percentage: bnnb.food_basket.zero? ? 0 : ((user_food / bnnb.food_basket) * 100).round(2)
    }
  end
end
