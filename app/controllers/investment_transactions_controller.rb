class InvestmentTransactionsController < ApplicationController
  before_action :set_investment
  before_action :set_investment_transaction, only: %i[show edit update destroy]
  load_and_authorize_resource

  def index
    @transactions = @investment.investment_transactions.order(transaction_date: :desc)

    # Filter by transaction type if specified
    @transactions = @transactions.where(transaction_type: params[:type]) if params[:type].present?

    # Filter by date range if specified
    if params[:start_date].present? && params[:end_date].present?
      begin
        start_date = Date.parse(params[:start_date])
        end_date = Date.parse(params[:end_date])
        @transactions = @transactions.where(transaction_date: start_date..end_date)
      rescue ArgumentError => e
        Rails.logger.warn "Invalid date format in params: #{e.message}"
        flash.now[:alert] = 'Invalid date format provided'
      end
    end

    # Analytics
    @total_contributions = @transactions.contributions.sum(:amount)
    @total_withdrawals = @transactions.withdrawals.sum(:amount)
    @total_income = @transactions.income.sum(:amount)
    @total_fees = @transactions.fees.sum(:amount)
  end

  def show; end

  def new
    @transaction = @investment.investment_transactions.new
    @transaction.user = current_user
    @transaction.transaction_date = Date.current
  end

  def edit; end

  def create
    @transaction = @investment.investment_transactions.new(investment_transaction_params)
    @transaction.user = current_user

    if @transaction.save
      redirect_to investment_path(@investment), notice: 'Transaction was successfully recorded.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @transaction.update(investment_transaction_params)
      redirect_to investment_investment_transactions_path(@investment), notice: 'Transaction was successfully updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @transaction.destroy
      redirect_to investment_investment_transactions_path(@investment), notice: 'Transaction was successfully deleted.'
    else
      redirect_to investment_investment_transactions_path(@investment), alert: 'Transaction could not be deleted.'
    end
  end

  private

  def set_investment
    @investment = current_user.investments.find(params[:investment_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to investments_path, alert: 'Investment not found.'
  end

  def set_investment_transaction
    @transaction = @investment.investment_transactions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to investment_investment_transactions_path(@investment), alert: 'Transaction not found.'
  end

  def investment_transaction_params
    params.require(:investment_transaction).permit(
      :amount, :transaction_date, :transaction_type, :description, :reference_number
    )
  end
end
