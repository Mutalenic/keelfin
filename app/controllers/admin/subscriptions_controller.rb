module Admin
  class SubscriptionsController < BaseController
    before_action :set_subscription, only: [:show, :edit, :update]

    def index
      @subscriptions = Subscription.includes(:user).order(created_at: :desc)
      @subscriptions = @subscriptions.where(plan_name: params[:plan]) if params[:plan].present?
      @subscriptions = @subscriptions.where(status: params[:status]) if params[:status].present?
    end

    def show; end

    def edit; end

    def update
      if @subscription.update(subscription_params)
        redirect_to admin_subscription_path(@subscription), notice: 'Subscription updated successfully.'
      else
        render :edit
      end
    end

    private

    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:plan_name, :status, :amount, :start_date, :end_date)
    end
  end
end
