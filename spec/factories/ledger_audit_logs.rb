FactoryBot.define do
  factory :ledger_audit_log, class: 'Ledger::AuditLog' do
    association :user
    association :account, factory: :ledger_account
    association :ledger_transaction
    event_type           { 'transaction_posted' }
    balance_before_ngwee { 10_000 }
    balance_after_ngwee  { 5_000 }
    currency             { 'ZMW' }
    metadata             { {} }
  end
end
