class InvestmentTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_investment
  before_action :set_investment_transaction, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to investment_path(@investment), alert: 'You are not authorized to perform this action.'
  end
  
  def index
    @transactions = @investment.investment_transactions.order(transaction_date: :desc)
    
    # Filter by transaction type if specified
    if params[:type].present?
      @transactions = @transactions.where(transaction_type: params[:type])
    end
    
    # Filter by date range if specified
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      @transactions = @transactions.where(transaction_date: start_date..end_date)
    end
    
    # Analytics
    @total_contributions = @transactions.contributions.sum(:amount)
    @total_withdrawals = @transactions.withdrawals.sum(:amount)
    @total_income = @transactions.income.sum(:amount)
    @total_fees = @transactions.fees.sum(:amount)
  end
  
  def new
    @transaction = @investment.investment_transactions.new
    @transaction.user = current_user
    @transaction.transaction_date = Date.current
  end
  
  def create
    @transaction = @investment.investment_transactions.new(investment_transaction_params)
    @transaction.user = current_user
    
    if @transaction.save
      redirect_to investment_path(@investment), notice: 'Transaction was successfully recorded.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @transaction.update(investment_transaction_params)
      redirect_to investment_investment_transactions_path(@investment), notice: 'Transaction was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
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
