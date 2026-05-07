class ProcessRecurringTransactionsJob < ApplicationJob
  queue_as :default

  def perform
    due = RecurringTransaction.due_today.includes(:user, :category)
    processed = 0
    failed = 0

    due.each do |rt|
      result = rt.process_transaction
      if result
        processed += 1
        Rails.logger.info "Processed recurring transaction #{rt.id} (#{rt.name}) for user #{rt.user_id}"
      else
        failed += 1
        Rails.logger.warn "Skipped recurring transaction #{rt.id} (#{rt.name}) — may have been processed already"
      end
    rescue StandardError => e
      failed += 1
      Rails.logger.error "Error processing recurring transaction #{rt.id}: #{e.message}"
    end

    Rails.logger.info "ProcessRecurringTransactionsJob complete: #{processed} processed, #{failed} skipped/failed"
  end
end
