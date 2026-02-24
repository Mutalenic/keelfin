class BnnbComparisonService
  def initialize(user, month = Date.current.beginning_of_month)
    @user = user
    @month = month
  end
  
  def compare
    bnnb = BnnbData.where(month: @month).first
    return nil unless bnnb
    
    {
      bnnb_total: bnnb.total_basket,
      user_total: user_total_spending,
      bnnb_food: bnnb.food_basket,
      user_food: user_food_spending,
      bnnb_non_food: bnnb.non_food_basket,
      user_non_food: user_non_food_spending,
      insights: generate_insights(bnnb)
    }
  end
  
  private
  
  def user_total_spending
    @user.payments.where('created_at >= ? AND created_at <= ?', @month, @month.end_of_month).sum(:amount)
  end
  
  def user_food_spending
    @user.payments.joins(:category)
      .where('categories.name ILIKE ?', '%food%')
      .where('payments.created_at >= ? AND payments.created_at <= ?', @month, @month.end_of_month)
      .sum(:amount)
  end
  
  def user_non_food_spending
    user_total_spending - user_food_spending
  end
  
  def generate_insights(bnnb)
    insights = []
    
    return insights if bnnb.food_basket.zero?
    
    food_diff = ((user_food_spending / bnnb.food_basket - 1) * 100).round(2)
    if food_diff < -10
      insights << "✅ Your food spending is #{food_diff.abs}% below JCTR average - great budgeting!"
    elsif food_diff > 10
      insights << "⚠️ Your food spending is #{food_diff}% above JCTR average. Consider meal planning."
    end
    
    if @user.monthly_income && @user.monthly_income < bnnb.total_basket
      insights << "🚨 Your income (K#{@user.monthly_income}) is below JCTR basic needs (K#{bnnb.total_basket}). Seek support."
    end
    
    insights
  end
end
