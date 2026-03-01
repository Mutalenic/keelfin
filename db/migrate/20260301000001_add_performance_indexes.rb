class AddPerformanceIndexes < ActiveRecord::Migration[7.2]
  def change
    # Three-column composite index for Budget#current_spending and similar
    # per-category, per-user, date-bounded SUM queries.
    # The existing (user_id, category_id) and (user_id, created_at) indexes
    # cannot satisfy both predicates in a single index scan; this one can.
    unless index_exists?(:payments, [:user_id, :category_id, :created_at],
                         name: 'index_payments_on_user_category_created_at')
      add_index :payments, [:user_id, :category_id, :created_at],
                name: 'index_payments_on_user_category_created_at'
    end

    # Composite index supporting the active goals dashboard query
    # (user_id + completed + target_date ORDER BY target_date).
    unless index_exists?(:financial_goals, [:user_id, :completed, :target_date],
                         name: 'index_financial_goals_on_user_completed_target_date')
      add_index :financial_goals, [:user_id, :completed, :target_date],
                name: 'index_financial_goals_on_user_completed_target_date'
    end

    # Index for the upcoming recurring transactions query
    # (user_id + active + next_occurrence).
    unless index_exists?(:recurring_transactions, [:user_id, :active, :next_occurrence],
                         name: 'index_recurring_on_user_active_next_occurrence')
      add_index :recurring_transactions, [:user_id, :active, :next_occurrence],
                name: 'index_recurring_on_user_active_next_occurrence'
    end
  end
end
