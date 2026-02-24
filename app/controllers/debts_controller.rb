class DebtsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_debt, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource
  
  def index
    @debts = current_user.debts.order(created_at: :desc)
    @analysis = DebtAnalysisService.new(current_user).analyze
  end
  
  def new
    @debt = current_user.debts.new
  end
  
  def create
    @debt = current_user.debts.new(debt_params)
    if @debt.save
      redirect_to debts_path, notice: 'Debt added successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def show
  end
  
  def edit
  end
  
  def update
    if @debt.update(debt_params)
      redirect_to debts_path, notice: 'Debt updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @debt.destroy
    redirect_to debts_path, notice: 'Debt deleted successfully.'
  end
  
  private
  
  def set_debt
    @debt = current_user.debts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to debts_path, alert: 'Debt not found.'
  end
  
  def debt_params
    params.require(:debt).permit(:lender_name, :principal_amount, :interest_rate, 
                                  :monthly_payment, :term, :start_date, :end_date, :status)
  end
end
