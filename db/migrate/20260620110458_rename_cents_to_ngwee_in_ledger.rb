class RenameCentsToNgweeInLedger < ActiveRecord::Migration[7.2]
  def change
    rename_column :ledger_entries, :amount_cents, :amount_ngwee
    rename_column :ledger_audit_logs, :balance_before_cents, :balance_before_ngwee
    rename_column :ledger_audit_logs, :balance_after_cents, :balance_after_ngwee
  end
end
