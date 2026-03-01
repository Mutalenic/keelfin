FactoryBot.define do
  factory :recurring_transaction do
    association :user
    association :category
    name { 'ZESCO Monthly' }
    amount { 450 }
    frequency { 'monthly' }
    start_date { Date.current }
    next_occurrence { Date.current + 1.month }
    active { true }
    is_essential { true }

    trait :inactive do
      active { false }
    end

    trait :due_soon do
      next_occurrence { 3.days.from_now.to_date }
    end
  end
end
