FactoryBot.define do
  factory :ledger_transaction, class: 'Ledger::Transaction' do
    association :user
    description      { 'Test transfer' }
    status           { 'pending' }
    idempotency_key  { SecureRandom.uuid }
    transaction_type { 'transfer' }
    metadata         { nil }

    trait :posted do status { 'posted' } end
    trait :failed do status { 'failed' } end
  end
end
