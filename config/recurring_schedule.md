# Recurring Transaction Schedule

To automate processing of due recurring transactions, add this cron entry on your server:

```
# Run daily at 00:05 to process recurring transactions
5 0 * * * cd /path/to/keelfin && bin/rails recurring:process RAILS_ENV=production >> log/cron.log 2>&1
```

Or if using Solid Queue / GoodJob in the future, schedule:
```ruby
ProcessRecurringTransactionsJob.set(wait_until: Date.tomorrow.midnight).perform_later
```

Manual run:
```
bin/rails recurring:process
```
