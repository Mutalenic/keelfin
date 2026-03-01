FactoryBot.define do
  factory :financial_goal do
    association :user
    name { 'Emergency Fund' }
    goal_type { 'saving' }
    target_amount { 30_000 }
    current_amount { 5_000 }
    start_date { Date.current }
    target_date { 1.year.from_now.to_date }

    trait :completed do
      completed { true }
      completion_date { Date.current }
      current_amount { 30_000 }
    end

    trait :overdue do
      target_date { 1.month.ago.to_date }
    end
  end
end
