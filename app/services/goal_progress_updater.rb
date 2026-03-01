class GoalProgressUpdater
  HISTORY_RETENTION_LIMIT = 365

  def initialize(goal, new_amount)
    @goal       = goal
    @new_amount = new_amount
  end

  # Returns true on success, false on failure.
  def call
    ActiveRecord::Base.transaction do
      @goal.update!(current_amount: @new_amount)
      @goal.check_completion

      # Append entry and apply rolling retention cap
      history = (@goal.progress_history || []) +
                [{ date: Date.current.to_s, amount: @new_amount.to_f }]
      @goal.update!(progress_history: history.last(HISTORY_RETENTION_LIMIT))
    end
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::ActiveRecordError => e
    Rails.logger.error "GoalProgressUpdater failed for goal #{@goal.id}: #{e.message}"
    false
  end
end
