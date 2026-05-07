class ChangeOpeningBalanceDefaultToNil < ActiveRecord::Migration[7.2]
  def change
    change_column_default :users, :opening_balance, from: 0.0, to: nil
  end
end
