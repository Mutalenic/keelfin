class SubscriptionsController < ApplicationController
  before_action :ensure_user_subscription
  before_action :set_subscription, only: %i[show update cancel]

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
      render :show, status: :unprocessable_content
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
      alert = @subscription.errors.full_messages.first || 'Could not upgrade subscription. Please try again.'
      redirect_to plans_subscription_path, alert: alert
    end
  end

  def checkout
    plan_name = params[:plan_name]
    unless %w[standard premium].include?(plan_name)
      return redirect_to plans_subscription_path, alert: 'Invalid plan selected.'
    end

    plan = Subscription::PLANS[plan_name.to_sym]
    service = DpoPayService.new(user: current_user, plan_name: plan_name, amount: plan[:price])
    result = service.create_token

    if result.success?
      session[:dpo_plan] = plan_name
      session[:dpo_token] = result.transaction_token
      redirect_to result.redirect_url, allow_other_host: true
    else
      redirect_to plans_subscription_path, alert: "Payment initiation failed: #{result.error}"
    end
  end

  def dpo_callback
    transaction_token = params[:TransactionToken] || session[:dpo_token]
    plan_name = session[:dpo_plan]

    if transaction_token.blank? || plan_name.blank?
      return redirect_to plans_subscription_path, alert: 'Invalid payment callback.'
    end

    service = DpoPayService.new(user: current_user, plan_name: plan_name, amount: 0)
    result = service.verify_payment(transaction_token)

    session.delete(:dpo_plan)
    session.delete(:dpo_token)

    if result.success?
      sub = current_user.ensure_subscription
      if sub.upgrade_to(plan_name)
        redirect_to subscription_path, notice: "Payment successful! You are now on the #{plan_name.capitalize} plan."
      else
        redirect_to subscription_path, alert: 'Payment received but plan upgrade failed. Please contact support.'
      end
    else
      redirect_to plans_subscription_path, alert: "Payment could not be verified: #{result.error}"
    end
  end

  def cancel
    if @subscription.cancel
      redirect_to subscription_path,
                  notice: 'Subscription canceled. You will have access until the end of your billing period.'
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
