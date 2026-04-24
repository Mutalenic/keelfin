class DebtPaymentsController < ApplicationController
  before_action :set_debt
  before_action :set_debt_payment, only: %i[destroy]

  def create
    @debt_payment = @debt.debt_payments.new(debt_payment_params)

    if @debt_payment.save
      redirect_to debt_path(@debt), notice: "Payment of K#{number_with_precision(@debt_payment.amount, precision: 2)} recorded."
    else
      redirect_to debt_path(@debt), alert: 'Could not record payment. Please check the details.'
    end
  end

  def destroy
    @debt_payment.destroy
    redirect_to debt_path(@debt), notice: 'Payment record removed.'
  end

  private

  def set_debt
    @debt = current_user.debts.find(params[:debt_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to debts_path, alert: 'Debt not found.'
  end

  def set_debt_payment
    @debt_payment = @debt.debt_payments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to debt_path(@debt), alert: 'Payment not found.'
  end

  def debt_payment_params
    params.require(:debt_payment).permit(:amount, :paid_on, :notes)
  end
end
