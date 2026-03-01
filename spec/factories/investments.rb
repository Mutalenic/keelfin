FactoryBot.define do
  factory :investment do
    association :user
    name            { "Lusaka Stock Exchange" }
    investment_type { "stocks" }
    initial_amount  { 10_000 }
    current_value   { 12_500 }
    start_date      { 1.year.ago.to_date }
    active          { true }
    risk_level      { 3 }

    trait :inactive do
      active { false }
    end
  end
end
