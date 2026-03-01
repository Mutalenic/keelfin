class RecurringTransactionsController < ApplicationController
  before_action :set_recurring_transaction, only: [:show, :edit, :update, :destroy, :toggle_active]
  load_and_authorize_resource
  
  def index
    @active_transactions = current_user.recurring_transactions.active.order(next_occurrence: :asc)
    @inactive_transactions = current_user.recurring_transactions.where(active: false).order(updated_at: :desc)
    
    # Analytics
    @monthly_impact = @active_transactions.sum(&:estimated_monthly_impact)
    @transactions_by_frequency = @active_transactions.group_by(&:frequency)
    @transactions_by_category = @active_transactions.group_by(&:category)
  end
  
  def show
    safe_name = ActiveRecord::Base.sanitize_sql_like(@recurring_transaction.name)
    @payment_history = Payment.where(user: current_user, category: @recurring_transaction.category)
                             .where('name LIKE ?', "%#{safe_name}%")
                             .order(created_at: :desc)
                             .limit(10)
  end
  
  def new
    @recurring_transaction = current_user.recurring_transactions.new
    @categories = current_user.categories
  end
  
  def create
    @recurring_transaction = current_user.recurring_transactions.new(recurring_transaction_params)
    
    if @recurring_transaction.save
      redirect_to recurring_transactions_path, notice: 'Recurring transaction was successfully created.'
    else
      @categories = current_user.categories
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @categories = current_user.categories
  end
  
  def update
    if @recurring_transaction.update(recurring_transaction_params)
      redirect_to recurring_transaction_path(@recurring_transaction), notice: 'Recurring transaction was successfully updated.'
    else
      @categories = current_user.categories
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @recurring_transaction.destroy
      redirect_to recurring_transactions_path, notice: 'Recurring transaction was successfully deleted.'
    else
      redirect_to recurring_transactions_path, alert: 'Recurring transaction could not be deleted.'
    end
  end
  
  def toggle_active
    @recurring_transaction.update(active: !@recurring_transaction.active)
    
    status = @recurring_transaction.active? ? 'activated' : 'paused'
    redirect_to recurring_transaction_path(@recurring_transaction), notice: "Recurring transaction was successfully #{status}."
  end
  
  def process_due
    due_transactions = current_user.recurring_transactions.due_today
    processed_count = 0
    
    due_transactions.each do |transaction|
      payment = transaction.process_transaction
      processed_count += 1 if payment.persisted?
    end
    
    redirect_to recurring_transactions_path, notice: "Successfully processed #{processed_count} recurring transactions."
  end
  
  private
  
  def set_recurring_transaction
    @recurring_transaction = current_user.recurring_transactions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to recurring_transactions_path, alert: 'Recurring transaction not found.'
  end
  
  def recurring_transaction_params
    params.require(:recurring_transaction).permit(
      :name, :amount, :frequency, :start_date, :end_date, 
      :category_id, :payment_method, :is_essential, :notes, :active
    )
  end
end
