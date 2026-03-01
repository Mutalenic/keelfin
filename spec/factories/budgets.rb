FactoryBot.define do
  factory :budget do
    association :user
    association :category
    monthly_limit { 5_000 }
    start_date    { Date.current.beginning_of_month }
  end
end
