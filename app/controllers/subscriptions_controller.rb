class SubscriptionsController < ApplicationController
  before_action :ensure_user_subscription
  before_action :set_subscription, only: [:show, :update, :cancel]

  def show
    # Show current subscription details
  end

  def new
    # Redirect to plans if user already has a subscription
    redirect_to plans_subscription_path if current_user.has_subscription?
  end

  def create
    # Create a free subscription for the user
    @subscription = Subscription.create_free_subscription(current_user)
    
    if @subscription
      redirect_to subscription_path, notice: 'Free subscription activated!'
    else
      redirect_to new_subscription_path, alert: 'Could not create subscription. Please try again.'
    end
  end

  def update
    if @subscription.update(subscription_params)
      redirect_to subscription_path, notice: 'Subscription updated successfully.'
    else
      render :show, status: :unprocessable_entity
    end
  end
  
  def plans
    # Show available subscription plans
    @plans = Subscription::PLANS
    @current_plan = current_user.subscription&.plan_name || 'free'
  end
  
  def upgrade
    # Upgrade to a paid plan
    plan_name = params[:plan_name]
    
    unless %w[free standard premium].include?(plan_name)
      return redirect_to plans_subscription_path, alert: 'Invalid plan selected.'
    end
    
    # Ensure user has a subscription
    @subscription = current_user.ensure_subscription
    
    if @subscription.upgrade_to(plan_name)
      redirect_to subscription_path, notice: "Successfully upgraded to #{plan_name.capitalize} plan!"
    else
      redirect_to plans_subscription_path, alert: 'Could not upgrade subscription. Please try again.'
    end
  end
  
  def cancel
    if @subscription.cancel
      redirect_to subscription_path, notice: 'Subscription canceled. You will have access until the end of your billing period.'
    else
      redirect_to subscription_path, alert: 'Could not cancel subscription. Please try again.'
    end
  end

  private
  
  def set_subscription
    @subscription = current_user.subscription
    redirect_to new_subscription_path unless @subscription
  end
  
  def ensure_user_subscription
    # Make sure every user has at least a free subscription
    current_user.ensure_subscription if current_user && !current_user.has_subscription?
  end
  
  def subscription_params
    params.require(:subscription).permit(:plan_name)
  end
end
