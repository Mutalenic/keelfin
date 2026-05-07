class DebtPayment < ApplicationRecord
  belongs_to :debt

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :paid_on, presence: true

  scope :ordered, -> { order(paid_on: :desc) }

  after_create :check_debt_paid_off

  private

  def check_debt_paid_off
    return if debt.status == 'paid_off'
    return unless debt.remaining_balance_from_payments <= 0

    debt.update(status: 'paid_off')
  end
end
