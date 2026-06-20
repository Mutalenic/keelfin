FactoryBot.define do
  factory :ledger_webhook_delivery, class: 'Ledger::WebhookDelivery' do
    association :webhook_endpoint, factory: :ledger_webhook_endpoint
    association :ledger_transaction
    event_type       { 'transaction.posted' }
    status           { 'pending' }
    payload          { {} }
    attempt_count    { 0 }

    trait :delivered do
      status           { 'delivered' }
      http_status_code { 200 }
      attempt_count    { 1 }
      last_attempted_at { Time.current }
    end

    trait :failed do
      status           { 'failed' }
      http_status_code { 500 }
      attempt_count    { 3 }
      last_attempted_at { Time.current }
    end
  end
end
