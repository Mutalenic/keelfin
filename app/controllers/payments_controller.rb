class PaymentsController < ApplicationController
  before_action :set_category, except: %i[create_global export_all]
  before_action :set_payment, only: %i[show edit update destroy]
  before_action :authorize_payment, only: %i[show edit update destroy]

  def create_global
    category = current_user.categories.find_by(id: params.dig(:payment, :category_id))
    return redirect_back_or_to(root_path, alert: 'Please select a valid category.') unless category

    @payment = category.payments.new(global_payment_params)
    @payment.user = current_user

    if @payment.save
      redirect_back_or_to(root_path, notice: 'Transaction added successfully.')
    else
      redirect_back_or_to(root_path, alert: @payment.errors.full_messages.to_sentence)
    end
  end

  def index
    @payments = @category.payments.order(created_at: :desc)
    @total_amount = @payments.sum(:amount)
  end

  def export
    payments = @category.payments.order(created_at: :desc)
    send_csv(payments, filename: "#{@category.name.parameterize}-transactions.csv")
  end

  def export_all
    payments = current_user.payments
      .includes(:category)
      .order(created_at: :desc)
    send_csv(payments, filename: "keelfin-all-transactions-#{Date.current}.csv", include_category: true)
  end

  def show; end

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
    params.require(:payment).permit(:name, :amount, :payment_method, :is_essential, :notes, :created_at)
  end

  def global_payment_params
    params.require(:payment).permit(:name, :amount, :payment_method, :is_essential, :notes, :created_at)
  end

  def authorize_payment
    authorize! :manage, @payment
  end

  def send_csv(payments, filename:, include_category: false)
    require 'csv'
    csv_data = CSV.generate(headers: true) do |csv|
      headers = ['Date', 'Name', 'Amount (ZMW)', 'Payment Method', 'Essential', 'Notes']
      headers.insert(2, 'Category') if include_category
      csv << headers

      payments.find_each do |p|
        row = [
          p.created_at.strftime('%Y-%m-%d'),
          p.name,
          format('%.2f', p.amount),
          p.payment_method,
          p.is_essential? ? 'Yes' : 'No',
          p.notes
        ]
        row.insert(2, p.category&.name) if include_category
        csv << row
      end
    end

    send_data csv_data, filename: filename, type: 'text/csv; charset=utf-8', disposition: 'attachment'
  end
end
