FactoryBot.define do
  factory :investment_transaction do
    association :investment
    association :user
    transaction_type { "contribution" }
    amount           { 2_000 }
    transaction_date { Date.current }
    notes            { "Monthly top-up" }
  end
end
