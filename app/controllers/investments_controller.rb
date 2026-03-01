class InvestmentsController < ApplicationController
  load_and_authorize_resource
  
  def index
    @investments = current_user.investments.includes(:investment_transactions).order(created_at: :desc)
    
    # Analytics
    @total_invested = @investments.sum(:current_value)
    @total_initial = @investments.sum(:initial_amount)
    @total_return = @total_invested - @total_initial
    @return_percentage = @total_initial > 0 ? ((@total_return / @total_initial) * 100).round(2) : 0
    
    # Group investments by type
    @investments_by_type = @investments.group_by(&:investment_type)
    
    # Calculate portfolio allocation
    @portfolio_allocation = calculate_portfolio_allocation
  end
  
  def show
    @transactions = @investment.investment_transactions.order(transaction_date: :desc).limit(10)
    
    # Calculate performance metrics
    @total_contributions = @investment.total_contributions
    @total_withdrawals = @investment.total_withdrawals
    @net_contributions = @investment.net_contributions
    @total_return = @investment.total_return
    @return_percentage = @investment.return_percentage
    @annualized_return = @investment.annualized_return
    
    # Prepare data for charts
    @value_history = prepare_value_history_data
    @transaction_history = prepare_transaction_history_data
  end
  
  def new
    @investment = current_user.investments.new
  end
  
  def create
    @investment = current_user.investments.new(investment_params)
    
    # Set the current value to match the initial amount for new investments
    @investment.current_value = @investment.initial_amount if @investment.current_value.nil?
    
    # Initialize value history with the initial amount
    if @investment.initial_amount > 0
      @investment.value_history = [{ date: Date.current.to_s, value: @investment.initial_amount.to_f }]
    end
    
    if @investment.save
      redirect_to investments_path, notice: 'Investment was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @investment.update(investment_params)
      redirect_to investment_path(@investment), notice: 'Investment was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @investment.destroy
      redirect_to investments_path, notice: 'Investment was successfully deleted.'
    else
      redirect_to investments_path, alert: 'Investment could not be deleted.'
    end
  end
  
  def update_value
    new_value = params[:current_value].to_f
    
    if @investment.update_current_value(new_value)
      redirect_to investment_path(@investment), notice: 'Investment value was successfully updated.'
    else
      redirect_to investment_path(@investment), alert: 'Failed to update investment value.'
    end
  end
  
  private
  
  def investment_params
    params.require(:investment).permit(
      :name, :investment_type, :initial_amount, :current_value, 
      :target_value, :start_date, :target_date, :risk_level,
      :institution, :account_number, :active, :notes
    )
  end
  
  def calculate_portfolio_allocation
    total = @investments.sum(:current_value)
    return {} if total <= 0
    
    allocation = {}
    @investments_by_type.each do |type, investments|
      type_total = investments.sum(&:current_value)
      percentage = ((type_total / total) * 100).round(1)
      allocation[type] = { total: type_total, percentage: percentage }
    end
    
    allocation
  end
  
  def prepare_value_history_data
    return [] if @investment.value_history.nil?
    
    @investment.value_history.sort_by { |entry| Date.parse(entry['date']) }
  end
  
  def prepare_transaction_history_data
    transactions = @investment.investment_transactions.order(transaction_date: :asc)
    
    # Group transactions by month
    transactions.group_by { |t| t.transaction_date.beginning_of_month }.map do |month, txns|
      {
        month: month.strftime('%b %Y'),
        contributions: txns.select { |t| t.transaction_type == 'contribution' }.sum(&:amount),
        withdrawals: txns.select { |t| t.transaction_type == 'withdrawal' }.sum(&:amount),
        income: txns.select { |t| ['dividend', 'interest'].include?(t.transaction_type) }.sum(&:amount),
        fees: txns.select { |t| t.transaction_type == 'fee' }.sum(&:amount)
      }
    end
  end
end
