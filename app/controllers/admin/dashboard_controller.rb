module Admin
  class DashboardController < BaseController
    def index
      @total_users = User.count
      @new_users_this_month = User.where('created_at >= ?', Date.current.beginning_of_month).count
      @active_subscriptions = Subscription.active.count
      @premium_subscriptions = Subscription.active.where(plan_name: 'premium').count
      @standard_subscriptions = Subscription.active.where(plan_name: 'standard').count
      @total_payments = Payment.count
      @total_payment_volume = Payment.sum(:amount)
      @recent_users = User.order(created_at: :desc).limit(5)
      @recent_payments = Payment.includes(:user, :category).order(created_at: :desc).limit(10)
    end
  end
end
