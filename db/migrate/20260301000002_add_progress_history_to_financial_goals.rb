class AddProgressHistoryToFinancialGoals < ActiveRecord::Migration[7.2]
  def change
    add_column :financial_goals, :progress_history, :jsonb, default: [], null: false
  end
end
