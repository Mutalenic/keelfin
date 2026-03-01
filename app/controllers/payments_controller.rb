class PaymentsController < ApplicationController
  before_action :set_category
  before_action :set_payment, only: %i[show edit update destroy]
  before_action :authorize_payment, only: %i[show edit update destroy]

  def index
    @payments = @category.payments.order(created_at: :desc)
    @total_amount = @payments.sum(:amount)
  end

  def new
    @payment = @category.payments.new
  end

  def edit; end

  def create
    @payment = @category.payments.new(payment_params)
    @payment.user = current_user

    if @payment.save
      redirect_to category_payments_path(@category), notice: 'Payment was successfully added.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @payment.update(payment_params)
      redirect_to category_payments_path(@category), notice: 'Payment was successfully updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @payment.destroy
      redirect_to category_payments_path(@category), notice: 'Payment was successfully deleted.'
    else
      redirect_to category_payments_path(@category), alert: 'Failed to delete payment.'
    end
  end

  private

  def set_category
    @category = current_user.categories.find(params[:category_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to categories_path, alert: 'Category not found.'
  end

  def set_payment
    @payment = @category.payments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to category_payments_path(@category), alert: 'Payment not found.'
  end

  def payment_params
    params.require(:payment).permit(:name, :amount, :payment_method, :is_essential, :notes)
  end

  def authorize_payment
    authorize! :manage, @payment
  end
end
