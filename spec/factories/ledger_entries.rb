FactoryBot.define do
  factory :ledger_entry, class: 'Ledger::Entry' do
    association :ledger_transaction
    association :account, factory: :ledger_account
    direction    { 'debit' }
    amount_ngwee { 5000 }
    currency     { 'ZMW' }

    trait :debit  do direction { 'debit' }  end
    trait :credit do direction { 'credit' } end
  end
end
