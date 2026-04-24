namespace :recurring do
  desc "Process all due recurring transactions"
  task process: :environment do
    due_count = RecurringTransaction.due_today.count
    puts "Processing #{due_count} due recurring transaction(s)..."
    ProcessRecurringTransactionsJob.perform_now
    puts "Done."
  end
end

namespace :budgets do
  desc "Send budget alert emails to users with budgets at/over 80%"
  task send_alerts: :environment do
    puts "Sending budget alerts..."
    SendBudgetAlertsJob.perform_now
    puts "Done."
  end
end
